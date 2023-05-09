<template>
    <table v-if="data && data.length">
      <thead>
        <tr>
          <th v-for="column in columns" :key="column">{{ column }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="row in data" :key="JSON.stringify(row)">
          <td v-for="column in columns" :key="column">{{ row[column] }}</td>
        </tr>
      </tbody>
    </table>
    <div v-else>No data available</div>
  </template>
  
  <script>
  export default {
    props: {
      data: Array,
    },
    computed: {
      columns() {
        if (!this.data || this.data.length === 0) return [];
        return Object.keys(this.data[0]);
      },
    },
  };
  </script>
  
  <style scoped>
  table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 1rem;
  }
  
  th,
  td {
    border: 1px solid #ccc;
    padding: 0.5rem;
    text-align: left;
  }
  
  th {
    background-color: #f3f3f3;
  }
  </style>
  