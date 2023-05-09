<template>
  <div>
    <h1>Data Table</h1>
    <div v-for="table in tables" :key="table.name">
      <h2>{{ table.name }}</h2>
      <table>
        <thead>
          <tr>
            <th v-for="column in table.columns" :key="column">{{ column }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="row in table.data" :key="row.id">
            <td v-for="column in table.columns" :key="column">{{ row[column] }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
import axios from "axios";

export default {
  data() {
    return {
      tables: []
    };
  },
  async created() {
    try {
      const response = await axios.get("http://localhost:3000");
      this.tables = response.data;
    } catch (error) {
      console.error("Error fetching data:", error);
    }
  }
};
</script>
