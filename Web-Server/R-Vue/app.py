import streamlit as st
import json
import time
import os
import plotly.graph_objects as go
import plotly.subplots as sp
import pandas as pd
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from google.oauth2 import service_account
from io import BytesIO

# Function to set up Google Drive API client
def get_gdrive_service():
    creds = service_account.Credentials.from_service_account_file(
        'scpower-cell-atlas-ea6689019916.json',
        scopes=['https://www.googleapis.com/auth/drive.readonly']
    )
    return build('drive', 'v3', credentials=creds)

# Function to fetch JSON from Google Drive
def fetch_gdrive_json(file_id):
    service = get_gdrive_service()
    try:
        file = service.files().get_media(fileId=file_id).execute()
        file_name = service.files().get(fileId=file_id, fields="name").execute().get('name')
        st.success(f"Successfully fetched *{file_name}*. Loading it...")
        time.sleep(2) 
        return json.loads(file.decode('utf-8'))
    except Exception as e:
        st.error(f"Error fetching file from Google Drive: {str(e)}")
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

def create_scatter_plot(data, x_axis, y_axis, size_axis):
    df = pd.DataFrame(data)
    
    # Convert columns to numeric, replacing non-numeric values with NaN
    df[x_axis] = pd.to_numeric(df[x_axis], errors='coerce')
    df[y_axis] = pd.to_numeric(df[y_axis], errors='coerce')
    df[size_axis] = pd.to_numeric(df[size_axis], errors='coerce')
    df['Detection.power'] = pd.to_numeric(df['Detection.power'], errors='coerce')
    
    # Remove rows with NaN values
    df = df.dropna(subset=[x_axis, y_axis, size_axis, 'Detection.power'])
    
    if df.empty:
        return None
    
    # Calculate size reference
    size_ref = 2 * df[size_axis].max() / (40**2)
    
    fig = go.Figure(go.Scatter(
        x=df[x_axis],
        y=df[y_axis],
        mode='markers',
        marker=dict(
            size=df[size_axis],
            sizemode='area',
            sizeref=size_ref,
            sizemin=4,
            color=df['Detection.power'],
            colorscale='Viridis',
            colorbar=dict(title="Detection power"),
            showscale=True
        ),
        text=df.apply(lambda row: f"Sample size: {row.get('sampleSize', 'N/A')}<br>Cells per individuum: {row.get('totalCells', 'N/A')}<br>Read depth: {row.get('readDepth', 'N/A')}<br>Detection power: {row.get('Detection.power', 'N/A')}", axis=1),
        hoverinfo='text'
    ))

    fig.update_layout(
        xaxis_title=x_axis,
        yaxis_title=y_axis,
        title="Power Results Scatter Plot"
    )

    return fig

def create_influence_plot(data, parameter_vector):
    df = pd.DataFrame(data)
    
    selected_pair = parameter_vector[0]
    study_type = parameter_vector[5]

    # Set grid dependent on parameter choice
    if selected_pair == "sc":
        x_axis, x_axis_label = "sampleSize", "Sample size"
        y_axis, y_axis_label = "totalCells", "Cells per sample"
    elif selected_pair == "sr":
        x_axis, x_axis_label = "sampleSize", "Sample size"
        y_axis, y_axis_label = "readDepth", "Read depth"
    else:
        x_axis, x_axis_label = "totalCells", "Cells per sample"
        y_axis, y_axis_label = "readDepth", "Read depth"

    # Check if the required columns exist
    required_columns = [x_axis, y_axis, 'sampleSize', 'totalCells', 'readDepth']
    missing_columns = [col for col in required_columns if col not in df.columns]
    if missing_columns:
        st.error(f"Missing required columns: {', '.join(missing_columns)}")
        return None

    # Select study with the maximal values 
    power_column = next((col for col in df.columns if 'power' in col.lower()), None)
    if not power_column:
        st.error("No power column found in the data.")
        return None
    max_study = df.loc[df[power_column].idxmax()]

    # Identify the columns for plotting
    plot_columns = [col for col in df.columns if any(keyword in col.lower() for keyword in ['power', 'probability', 'prob'])]
    if not plot_columns:
        st.error("No suitable columns found for plotting.")
        return None

    # Create subplots
    fig = sp.make_subplots(rows=1, cols=2, shared_yaxes=True)

    # Plot cells per person
    df_plot1 = df[df[y_axis] == max_study[y_axis]]
    for col in plot_columns:
        fig.add_trace(
            go.Scatter(
                x=df_plot1[x_axis], y=df_plot1[col],
                mode='lines+markers', name=col,
                text=[f'Sample size: {row.sampleSize}<br>Cells per individuum: {row.totalCells}<br>Read depth: {row.readDepth}<br>{col}: {row[col]:.3f}' for _, row in df_plot1.iterrows()],
                hoverinfo='text'
            ),
            row=1, col=1
        )

    # Plot read depth
    df_plot2 = df[df[x_axis] == max_study[x_axis]]
    for col in plot_columns:
        fig.add_trace(
            go.Scatter(
                x=df_plot2[y_axis], y=df_plot2[col],
                mode='lines+markers', name=col, showlegend=False,
                text=[f'Sample size: {row.sampleSize}<br>Cells per individuum: {row.totalCells}<br>Read depth: {row.readDepth}<br>{col}: {row[col]:.3f}' for _, row in df_plot2.iterrows()],
                hoverinfo='text'
            ),
            row=1, col=2
        )

    # Update layout
    fig.update_layout(
        title="Power Analysis Results",
        xaxis_title=x_axis_label,
        xaxis2_title=y_axis_label,
        yaxis_title="Probability",
        legend=dict(orientation='h', yanchor='bottom', y=1.02, xanchor='right', x=1)
    )

    # Add vertical lines
    fig.add_vline(x=max_study[x_axis], line_dash="dot", row=1, col=1)
    fig.add_vline(x=max_study[y_axis], line_dash="dot", row=1, col=2)

    return fig

def main():
    st.title("scPower Power Results")
    scatter_file_id   = "1NkBP3AzLWuXKeYwgtVdTYxrzLjCuqLkR"
    influence_file_id = "1viAH5OEyhSoQjdGHi2Cm0_tFHrr1Z3GQ"
    
    # Initialize session state
    if 'scatter_data' not in st.session_state:
        st.session_state.scatter_data = None
    if 'influence_data' not in st.session_state:
        st.session_state.influence_data = None
    if 'uploaded_data' not in st.session_state:
        st.session_state.uploaded_data = None
    if 'uploaded_file' not in st.session_state:
        st.session_state.uploaded_file = None
    if 'show_user_options' not in st.session_state:
        st.session_state.show_user_options = False

    # Fetch initial data if not already present
    if st.session_state.scatter_data is None:
        st.session_state.scatter_data = fetch_gdrive_json(scatter_file_id)
    if st.session_state.influence_data is None:
        st.session_state.influence_data = fetch_gdrive_json(influence_file_id)

    # Add the new influence plot
    if st.session_state.influence_data is not None:
        st.subheader("Influence Plot")
        parameter_vector = ["sc", 1000, 100, 200, 400000000, "eqtl"]
        fig = create_influence_plot(st.session_state.influence_data, parameter_vector)
        if fig is not None:
            st.plotly_chart(fig)
    else:
        st.warning("No influence data available. Please check your data source.")
    
    # Create scatter plot
    st.subheader("Power Results Scatter Plot")
    if isinstance(st.session_state.scatter_data, list) and len(st.session_state.scatter_data) > 0:
        x_axis = st.selectbox("Select X-axis", options=st.session_state.scatter_data[0].keys())
        y_axis = st.selectbox("Select Y-axis", options=st.session_state.scatter_data[0].keys())
        size_axis = st.selectbox("Select Size-axis", options=st.session_state.scatter_data[0].keys())

        fig = create_scatter_plot(st.session_state.scatter_data, x_axis, y_axis, size_axis)
        if fig is not None:
            st.plotly_chart(fig)
            st.session_state.show_user_options = True
    else:
        st.warning("No data available for plotting. Please fetch or upload data first.")

    # after plots are being drawn, show user options
    if st.session_state.show_user_options:
        st.subheader("Upload Your Own Data")
        uploaded_file = st.file_uploader("Choose a file to upload")
    
        if uploaded_file is not None and uploaded_file != st.session_state.uploaded_file:
            st.session_state.uploaded_file = uploaded_file
            file_extension = os.path.splitext(uploaded_file.name)[1].lower()
            if file_extension == ".json":
                st.session_state.uploaded_data = read_json_file(uploaded_file)
                st.success("File uploaded successfully!")
            else:
                st.error("Error: The uploaded file is not a valid JSON file.")
                st.session_state.uploaded_data = None        

        if st.session_state.uploaded_data is not None:
            st.subheader("Uploaded Data:")
            if isinstance(st.session_state.uploaded_data, list):
                st.write(f"Number of items: {len(st.session_state.uploaded_data)}")
            st.json(st.session_state.uploaded_data)

if __name__ == "__main__":
    main()