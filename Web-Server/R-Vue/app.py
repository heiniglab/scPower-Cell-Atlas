import streamlit as st
import requests
import json
import io

def fetch_api_data(api_url):
    try:
        response = requests.get(api_url)
        response.raise_for_status()  # Raise an exception for bad status codes
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
        return json.loads(content)
    except json.JSONDecodeError:
        st.error("The uploaded file is not valid JSON.")
        return None

def main():
    st.title("scPower Power Results")
    api_url = "http://localhost:8000/data"
    
    uploaded_file = st.file_uploader("Choose a JSON file", type=['json'])

    if st.button("Fetch Data"):
        if uploaded_file is None:
            print("api fetch")
            data = fetch_api_data(api_url)
        else:
            print("read file")
            data = read_json_file(uploaded_file)

        if data is not None:
            st.subheader("Power Results:")
            if isinstance(data, list):
                st.write(f"Number of items: {len(data)}")
            
            st.json(data)

if __name__ == "__main__":
    main()