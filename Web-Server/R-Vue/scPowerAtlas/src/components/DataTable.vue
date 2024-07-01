<template>
    <div>
      <h1>Data Table</h1>
      <table v-if="data.length">
        <thead>
          <tr>
            <th v-for="(value, key) in data[0]" :key="key">{{ key }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(row, index) in data" :key="index">
            <td v-for="(value, key) in row" :key="key">{{ value }}</td>
          </tr>
        </tbody>
      </table>
      <p v-else>Loading data...</p>
    </div>
  </template>
  
  <script>
  import axios from 'axios';
  
  export default {
    data() {
      return {
        data: [],
      };
    },
    created() {
      this.fetchData();
    },
    methods: {
      fetchData() {
        axios.get('http://localhost:8000/data?dataset=mtcars')
          .then(response => {
            this.data = response.data;
          })
          .catch(error => {
            console.error('Error fetching data:', error);
          });
      },
    },
  };
  </script>
  
  <style>
  /* Global Styles */
  body {
    font-family: Avenir, Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-align: center;
    color: #2c3e50;
    background-color: #ffffff; /* Change background color to white */
    margin: 0;
    padding: 0;
  }
  
  #app {
    margin-top: 60px;
  }
  
  table {
    width: 100%;
    border-collapse: collapse;
    background-color: #ffffff; /* Ensure table background is white */
  }
  
  th, td {
    border: 1px solid #dddddd; /* Light grey border */
    padding: 8px;
    text-align: left;
  }
  
  th {
    background-color: #f4f4f4; /* Light grey header background */
  }
  </style>
  