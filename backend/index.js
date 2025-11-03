import http from 'http';
import pg from 'pg';

const { Client } = pg;
const port = process.env.PORT || 3001;

let client = null;
let successfulConnection = false;
let connectionAttempted = false;
const maxRetries = 10;
const retryDelay = 3000; 

function createClient() {
  return new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    connectionTimeoutMillis: 5000,
    idleTimeoutMillis: 30000,
  });
}

async function connectToDatabase() {
  if (connectionAttempted) return;
  
  connectionAttempted = true;
  let retries = 0;
  
  while (retries < maxRetries && !successfulConnection) {
    try {
      if (client) {
        try {
          await client.end();
        } catch (err) {
        }
      }
      
      client = createClient();
      
      console.log(`Tentando conectar ao banco (tentativa ${retries + 1}/${maxRetries})...`);
      await client.connect();
      successfulConnection = true;
      console.log('Conectado ao DB com sucesso');
      break;
    } catch (err) {
      retries++;
      console.error(`Falha de conexão (attempt ${retries}/${maxRetries}):`, err.message);
      
      if (client) {
        try {
          await client.end();
        } catch (endErr) {
        }
        client = null;
      }
      
      if (retries < maxRetries) {
        console.log(`Aguardando ${retryDelay/1000} segundos antes da próxima tentativa...`);
        await new Promise(resolve => setTimeout(resolve, retryDelay));
      }
    }
  }
  
  if (!successfulConnection) {
    console.error('Todas as tentativas de conexão falharam');
  }
}

connectToDatabase();

async function healthCheck() {
  if (!successfulConnection || !client) {
    return { database: false, status: 'connecting', message: 'Tentando conectar ao banco...' };
  }
  
  try {
    const result = await client.query('SELECT 1 as health_check');
    return { database: true, status: 'healthy', message: 'Conexão com banco OK' };
  } catch (error) {
    successfulConnection = false;
    return { database: false, status: 'unhealthy', message: error.message };
  }
}

async function checkDatabaseSetup() {
  if (!successfulConnection || !client) return false;
  
  try {
    const result = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'users'
      );
    `);
    return result.rows[0].exists;
  } catch (error) {
    console.error('Erro ao verificar tabelas:', error.message);
    return false;
  }
}

async function executeQuery(query, params = []) {
  if (!successfulConnection || !client) {
    throw new Error('Database not connected');
  }
  
  try {
    return await client.query(query, params);
  } catch (error) {
    if (error.message.includes('connection') || error.message.includes('ECONNREFUSED')) {
      console.log('Conexão perdida, tentando reconectar...');
      successfulConnection = false;
      connectionAttempted = false;
      await connectToDatabase();
      
      if (successfulConnection && client) {
        return await client.query(query, params);
      } else {
        throw new Error('Falha ao reconectar ao banco de dados');
      }
    }
    throw error;
  }
}

http.createServer(async (req, res) => {
  console.log(`Request: ${req.method} ${req.url}`);

  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (req.url === "/health" && req.method === "GET") {
    const health = await healthCheck();
    const tablesExist = await checkDatabaseSetup();
    
    res.setHeader("Content-Type", "application/json");
    res.writeHead(200);
    res.end(JSON.stringify({
      ...health,
      tables_initialized: tablesExist,
      timestamp: new Date().toISOString()
    }));
    return;
  }

  if (req.url === "/api" && req.method === "GET") {
    res.setHeader("Content-Type", "application/json");
    
    let result;
    let error = null;
    let tablesExist = false;

    try {
      if (!successfulConnection) {
        console.log('Sem conexão, tentando reconectar...');
        connectionAttempted = false;
        await connectToDatabase();
      }

      if (successfulConnection) {
        tablesExist = await checkDatabaseSetup();
        
        if (!tablesExist) {
          throw new Error('Tabelas ainda não foram inicializadas');
        }
        
        result = (await executeQuery("SELECT * FROM users LIMIT 1")).rows[0];
        console.log('Query executada com sucesso');
      } else {
        throw new Error('Banco não conectado');
      }
    } catch (err) {
      console.error('Query error:', err.message);
      error = err.message;
    }

    const data = {
      database: successfulConnection,
      userAdmin: result?.role === "admin",
      tables_initialized: tablesExist,
      error: error,
      timestamp: new Date().toISOString()
    }

    if (error) {
      res.writeHead(503);
    } else {
      res.writeHead(200);
    }
    
    res.end(JSON.stringify(data));
    return;
  }

  res.writeHead(404);
  res.end(JSON.stringify({ error: "Route not found", path: req.url }));
}).listen(port, () => {
  console.log(`Backend server is listening on port ${port}`);
  console.log(`Environment variables:`);
  console.log(` - DB_HOST: ${process.env.DB_HOST}`);
  console.log(` - DB_PORT: ${process.env.DB_PORT}`);
  console.log(` - DB_USER: ${process.env.DB_USER}`);
  console.log(` - DB_NAME: ${process.env.DB_NAME}`);
  console.log(` - PORT: ${port}`);
});


process.on('SIGTERM', async () => {
  console.log('Received SIGTERM, shutting down gracefully');
  try {
    if (client) {
      await client.end();
      console.log('Database connection closed');
    }
    process.exit(0);
  } catch (err) {
    console.error('Error during shutdown:', err);
    process.exit(1);
  }
});

process.on('SIGINT', async () => {
  console.log('Received SIGINT, shutting down gracefully');
  try {
    if (client) {
      await client.end();
      console.log('Database connection closed');
    }
    process.exit(0);
  } catch (err) {
    console.error('Error during shutdown:', err);
    process.exit(1);
  }
});
