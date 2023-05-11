<template>
  <div v-if="data">
    <div v-for="(tableData, tableName) in data" :key="tableName">
      <h2 @click="toggleTable(tableName)">
        {{ tableName }} <span>{{ tableStates[tableName] ? '▼' : '▶' }}</span>
      </h2>
      <table-component
        v-show="tableStates[tableName]"
        :data="tableData"
      />
      <button @click="changePage(tableName, -1)" :disabled="!canGoPrev(tableName)">Previous</button>
      <button @click="changePage(tableName, 1)" :disabled="!canGoNext(tableName)">Next</button>
    </div>
  </div>
</template>

<script>
import axios from "axios";
import TableComponent from "./components/TableComponent.vue";

export default {
  name: "App",
  components: {
    TableComponent,
  },
  data() {
      return {
        data: null,
        loading: true,
        error: null,
        tableStates: {
          disp_fun_estimation_results: false,
          power_results: false,
          gamma_linear_fit_results: false,
          gene_ranks: false,
        },
        pages: {
          disp_fun_estimation_results: 1,
          power_results: 1,
          gamma_linear_fit_results: 1,
          gene_ranks: 1,
        },
        limits: {
          disp_fun_estimation_results: 10,
          power_results: 10,
          gamma_linear_fit_results: 6,
          gene_ranks: 10,
        },
        hasMore: {
          disp_fun_estimation_results: true,
          power_results: true,
          gamma_linear_fit_results: true,
          gene_ranks: true,
        },
      };
    },

  methods: {
    toggleTable(tableName) {
      this.tableStates[tableName] = !this.tableStates[tableName];
    },

    async fetchData() {
      this.loading = true;

      try {
        const tableNames = Object.keys(this.pages);
        const requests = tableNames.map((tableName) =>
          axios.get("http://localhost:3000/data", {
            params: {
              table: tableName,
              page: this.pages[tableName],
              limit: this.limits[tableName],
            },
          })
        );

        const responses = await Promise.all(requests);
        this.data = responses.reduce((acc, response, index) => {
          const tableName = tableNames[index];
          acc[tableName] = response.data[tableName];
          this.hasMore[tableName] =
            response.data[tableName].length >= this.limits[tableName];
          return acc;
        }, {});

      } catch (error) {
        this.error = "Error fetching data from the server";
        console.error(error);
      } finally {
        this.loading = false;
      }
    },

    async changePage(tableName, delta) {
      this.pages[tableName] += delta;
      await this.fetchData();
    },

    canGoPrev(tableName) {
      return this.pages[tableName] > 1;
    },

    canGoNext(tableName) {
      return this.hasMore[tableName];
    },
  },

  async created() {
    await this.fetchData();
  },
};
</script>
