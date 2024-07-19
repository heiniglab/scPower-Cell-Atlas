import streamlit as st
import pandas as pd
import requests

# Function to load data from API
@st.cache_data
def load_data_from_api(api_url):
    response = requests.get(api_url)
    if response.status_code == 200:
        return pd.DataFrame(response.json())
    else:
        st.error(f"Failed to fetch data: HTTP {response.status_code}")
        return None

# Streamlit app
def main():
    st.title("API Data Viewer")

    # API URL input
    api_url = st.text_input("Enter API URL", value="http://localhost:8000/data")
    
    if st.button("Load Data"):
        # Load the data
        df = load_data_from_api(api_url)
        
        if df is not None:
            # Display basic info
            st.write(f"Rows: {df.shape[0]}, Columns: {df.shape[1]}")
            
            # Search functionality
            search = st.text_input("Search in any column:")
            if search:
                df = df[df.astype(str).apply(lambda row: row.str.contains(search, case=False).any(), axis=1)]
            
            # Display the dataframe
            st.dataframe(df)

if __name__ == "__main__":
    main()