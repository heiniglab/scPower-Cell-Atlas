const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;

// Update this configuration with your PostgreSQL database information.
const pool = new Pool({
  host: '127.0.0.1',
  port: '5432',
  user: 'postgres',
  password: 'asdasd12x',
  database: 'todos',
});

const convertPrimaryKey = (rows) => {
  return rows.map((row) => {
    row.primary_key = row.primary_key.toString('hex');
    return row;
  });
};

// Use CORS middleware
app.use(cors());

app.get('/data', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    const dispFunPromise = pool.query('SELECT * FROM disp_fun_estimation_results LIMIT $1 OFFSET $2', [limit, offset]);
    const powerResultPromise = pool.query('SELECT * FROM power_results LIMIT $1 OFFSET $2', [limit, offset]);
    const gammaFitsPromise = pool.query('SELECT * FROM gamma_linear_fit_results LIMIT $1 OFFSET $2', [limit, offset]);
    const geneRanksPromise = pool.query('SELECT * FROM gene_ranks LIMIT $1 OFFSET $2', [limit, offset]);

    const [dispFunResult, powerResult, gammaFitsResult, geneRanksResult] = await Promise.all([
      dispFunPromise,
      powerResultPromise,
      gammaFitsPromise,
      geneRanksPromise,
    ]);

    res.json({
      disp_fun_estimation_results: convertPrimaryKey(dispFunResult.rows),
      gamma_linear_fit_results: convertPrimaryKey(gammaFitsResult.rows),
      gene_ranks: geneRanksResult.rows,
      power_results: convertPrimaryKey(powerResult.rows),
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(port, () => {
  console.log(`Server is listening on port ${port}`);
});
