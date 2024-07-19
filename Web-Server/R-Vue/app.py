import streamlit as st
import requests
import json

def fetch_api_data(api_url):
    try:
        response = requests.get(api_url)
        response.raise_for_status()  # Raise an exception for bad status codes
        return response.text, response.headers.get('content-type')
    except requests.RequestException as e:
        return str(e), None

def main():
    st.title("scPower Power Results")

    # API URL input
    api_url = st.text_input("Enter API URL", value="http://localhost:8000/data")
    
    if st.button("Fetch Data"):
        data, content_type = fetch_api_data(api_url)

        st.subheader("Power Results:")
        try:
            parsed_data = json.loads(data)
            
            if isinstance(parsed_data, list):
                st.write(f"Number of items: {len(parsed_data)}")
            
            st.json(parsed_data)
               
        except json.JSONDecodeError:
            st.error("The API response is not valid JSON.")

if __name__ == "__main__":
    main()