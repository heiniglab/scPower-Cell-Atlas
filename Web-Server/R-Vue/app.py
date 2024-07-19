import streamlit as st
import requests
import json
import time
import os

def fetch_api_data(api_url):
    try:
        response = requests.get(api_url)
        response.raise_for_status()  # Raise an exception for bad status codes
        st.success("Successfully fetched the data. Loading it...")
        time.sleep(2)    
        return response.json()
    except requests.RequestException as e:
        st.error(f"API Error: {str(e)}")
        return None
    except json.JSONDecodeError:
        st.error("The API response is not valid JSON.")
        return None

def read_json_file(file):
    try:
        content = file.getvalue().decode("utf-8")
        st.success("File successfully uploaded and validated as JSON...")
        time.sleep(2)
        return json.loads(content)
    except json.JSONDecodeError:
        st.error("The uploaded file is not valid JSON.")
        return None

def main():
    st.title("scPower Power Results")
    api_url = "http://localhost:8000/data"
    
    uploaded_file = st.file_uploader("Choose a file to upload")

    if st.button("Fetch Data"):
        if uploaded_file is None:
            print("api fetch")
            data = fetch_api_data(api_url)
        else:
            print("read file")
            file_extension = os.path.splitext(uploaded_file.name)[1].lower()

            if file_extension == ".json":
                data = read_json_file(uploaded_file)
            else:
                st.error("Error: The uploaded file is not a valid JSON file.")

        if data is not None:
            st.subheader("Power Results:")
            if isinstance(data, list):
                st.write(f"Number of items: {len(data)}")
            
            st.json(data)

if __name__ == "__main__":
    main()