import streamlit as st
import logging
import json
import time
import tempfile
import os
import plotly.graph_objects as go
import plotly.subplots as sp
import pandas as pd
import numpy as np
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from google.oauth2 import service_account
from io import BytesIO
import subprocess
import json

from home import show_home_page
from description import show_description_page
from license import show_license_page
from tutorial import show_tutorial_page

logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')


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
        st.session_state.success_message.success(f"Successfully fetched *{file_name}*. Loading it...")
        time.sleep(2) 
        return json.loads(file.decode('utf-8'))
    except Exception as e:
        st.error(f"Error fetching file from Google Drive: {str(e)}")
        return None

def read_json_file(file_path):
    try:
        with open(file_path, 'r') as file:
            content = file.read()
        st.session_state.success_message.success("File successfully uploaded and validated as JSON...")
        time.sleep(2)
        return json.loads(content)
    except FileNotFoundError:
        st.error(f"The file '{file_path}' was not found.")
        return None
    except json.JSONDecodeError:
        st.error("The uploaded file is not valid JSON.")
        return None
    except Exception as e:
        st.error(f"An error occurred while reading the file: {str(e)}")
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
        yaxis_title=y_axis
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
        xaxis_title=x_axis_label,
        xaxis2_title=y_axis_label,
        yaxis_title="Probability",
        legend=dict(orientation='h', yanchor='bottom', y=1.02, xanchor='right', x=1)
    )

    # Add vertical lines
    fig.add_vline(x=max_study[x_axis], line_dash="dot", row=1, col=1)
    fig.add_vline(x=max_study[y_axis], line_dash="dot", row=1, col=2)

    return fig

def json_safe(obj):
    if isinstance(obj, np.ndarray):
        return obj.tolist()
    elif isinstance(obj, (np.int_, np.intc, np.intp, np.int8, np.int16, np.int32, np.int64, np.uint8, np.uint16, np.uint32, np.uint64)):
        return int(obj)
    elif isinstance(obj, (np.float_, np.float16, np.float32, np.float64)):
        return float(obj)
    elif isinstance(obj, (np.bool_)):
        return bool(obj)
    elif isinstance(obj, (np.string_, np.unicode_)):
        return str(obj)
    elif isinstance(obj, dict):
        return {str(k): json_safe(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [json_safe(i) for i in obj]
    return obj

def extract_and_filter(celltypes, assay_filter=None, tissue_filter=None):
    assays = set()
    tissues = set()
    filtered_celltypes = celltypes

    if assay_filter and assay_filter != "All":
        filtered_celltypes = [ct for ct in filtered_celltypes if ct.startswith(assay_filter)]
    
    if tissue_filter and tissue_filter != "All":
        filtered_celltypes = [ct for ct in filtered_celltypes if ct.split('_')[1] == tissue_filter]

    for celltype in celltypes:
        parts = celltype.split('_')
        if len(parts) >= 3:
            assays.add(parts[0])
            tissues.add(parts[1])
    
    return sorted(list(assays)), sorted(list(tissues)), filtered_celltypes

# Callback functions to update session state
def update_assay():
    st.session_state.tissue = "All"


def perform_analysis():
    st.title("Detect DE/eQTL genes")
    scatter_file_id   = "1NkBP3AzLWuXKeYwgtVdTYxrzLjCuqLkR"
    influence_file_id = "1viAH5OEyhSoQjdGHi2Cm0_tFHrr1Z3GQ"

    if 'assay' not in st.session_state:
        st.session_state.assay = "All"
    if 'tissue' not in st.session_state:
        st.session_state.tissue = "All"

    # Custom CSS for the hover effect
    st.markdown("""
        <style>
        .hover-text {
            position: relative;
            display: inline-block;
            cursor: help;
        }

        .hover-text .hover-content {
            visibility: hidden;
            width: 510px;
            background-color: #1E2A3A;
            color: #fff;
            text-align: left;
            border-radius: 6px;
            padding: 10px;
            position: absolute;
            z-index: 1;
            top: 0;
            left: 0;
            opacity: 0;
            transition: opacity 0.3s;
            transform: translateX(-570px);
        }

        .hover-text:hover .hover-content {
            visibility: visible;
            opacity: 1;
        }
        </style>
                

        <script>
            var elements = document.getElementsByClassName('hover-text');
            for (var i = 0; i < elements.length; i++) {
                elements[i].addEventListener('touchstart', function() {
                    var content = this.getElementsByClassName('hover-content')[0];
                    content.style.visibility = content.style.visibility === 'visible' ? 'hidden' : 'visible';
                    content.style.opacity = content.style.opacity === '1' ? '0' : '1';
                });
            }
        </script>
        """, unsafe_allow_html=True)
    
    # Initialize session state
    if 'scatter_data' not in st.session_state:
        st.session_state.scatter_data = None
    if 'influence_data' not in st.session_state:
        st.session_state.influence_data = None
    if 'success_message' not in st.session_state:
        st.session_state.success_message = st.empty()

    all_celltypes = pd.read_csv('database/main_table.csv')['id_to_name'].tolist()

    assays, tissues, _ = extract_and_filter(all_celltypes)

    # Create scatter plot
    with st.expander("General Parameters", expanded=True):
        study_type = st.radio(
            "Study type:",
            ["de", "eqtl"])
        organism = st.selectbox("Organisms", ["Homo sapiens", "Mus musculus"])
        selected_assay = st.selectbox("Assays", ["All"] + assays, key='assay', on_change=update_assay)

        _, tissues, _ = extract_and_filter(all_celltypes, assay_filter=selected_assay)
        selected_tissue = st.selectbox("Tissues", ["All"] + tissues, key='tissue')
        
        _, _, filtered_celltypes = extract_and_filter(all_celltypes, assay_filter=selected_assay, tissue_filter=selected_tissue)
        celltype = st.selectbox("Cell Types", filtered_celltypes)
    
    with st.expander("Advanced Options", expanded=False):
        col1, col2 = st.columns([3, 3])
        
        with col1:
            ct_freq_slider = st.slider("Cell Type Frequency", 0.0, 1.0, 0.1, step = 0.05, help="Frequency of the cell type of interest.")
            sample_size_ratio_slider = st.slider("Sample Size Ratio", 0.0, 50.0, 1.0, step = 0.05, help="ratio between sample size of group 0 (control group) and group 1 (Ratio=1 in case of balanced design)")
            ref_study = st.selectbox("Reference Study", ["Blueprint (CLL) iCLL-mCLL", "Blueprint (CLL) mCLL-uCLL", "Blueprint (CLL) uCLL-iCLL", "Moreno-Moral (Macrophages)", "Nicodemus-Johnson_AEC", "Pancreas_alphabeta", "Pancreas_ductacinar", "Custom"])
            total_budget = st.slider("Total Budget", step=500,min_value =0,value = 50000, help="The total budget available for the sequencing")
        
        with col2:
            parameter_grid = st.selectbox("Parameter Grid", ["samples - cells per sample", "samples - reads per cell", "cells per sample - reads per cell"])
            rangeX_min = st.slider("Sample size (min)", value=10, step=1, help="Minimal value of the tested ranges for the parameter on the x-Axis.")
            rangeX_max = st.slider("Sample size (max)", value=50, step=1, help="Maximum value of the tested ranges for the parameter on the x-Axis.")
            
            rangeY_min = st.slider("Cells (min)",value=2000, step=1),
            rangeY_max = st.slider("Cells (max)",value=10000, step=1),
            
            steps = st.slider("Steps", min_value=0, value=5, step=1, help= "number of values in the parameter ranges for the parameter grid")

    with st.expander("Cost and Experimental Parameters", expanded=False):
        col1, col2 = st.columns([3, 3])
        with col1:
            cost_10x_kit = st.slider("Cost 10X kit", value = 5600, step=100,min_value=0, help="Cost for one 10X Genomics kit")     
            cost_flow_cell = st.slider("Cost Flow Cell", value = 14032, step=100,min_value=0, help="Cost for one flow cell")
            reads_per_flow_cell = st.slider("Number of reads per flow cell", value = 4100000000, step=10000,min_value=0)   
            cells_per_lane = st.slider("Cells per lane", value = 8000, step=500,min_value=0, help="Number of cells meassured on one 10X lane (dependent on the parameter \"Reactions Per Kit\")")
            
        with col2: 
            reactions_per_kit = st.slider("Reactions Per Kit", value = 6, step = 1, min_value= 1, help="Number of reactions/lanes on one 10X kit (different kit versions possible)")
            p_value = st.slider("P-value", value=0.05,step=0.01,min_value=0.0,max_value=1.0, help="Significance threshold")
            multiple_testing_method = st.selectbox("Multiple testing method", ["FDR", "FWER", "None"])
            indepsnps = st.slider("Independent SNPs", value=10, min_value=1, step=1),
    
    with st.expander("Mapping and Multiplet estimation", expanded=False):
        col1, col2 = st.columns([3, 3])
        with col1:
            mapping_efficiency = st.slider("Mapping efficiency", value = 0.8,step=0.05,min_value=0.0,max_value=1.0)
            multiplet_rate = st.slider("Multiplet Rate", value = 7.67e-06,step=1e-6,min_value=0.0, help="Rate factor to calculate the number of multiplets dependent on the number of cells loaded per lane. We assume a linear relationship of multiplet fraction = cells per lane * multiplet rate.")
            multiplet_factor = st.slider("Multiplet Factor", value = 1.82, step=0.1,min_value=1.0, help="Multiplets have a higher fraction of reads per cell than singlets, the multiplet factor shows the ratio between the reads.")
        
        with col2:
            min_num_UMI_per_gene = st.slider("Minimal number of UMI per gene", value = 3, step=1,min_value=1)
            fraction_of_indiv = st.slider("Fraction of individuals", value = 0.5,step=0.05,min_value=0.0,max_value=1.0)
            skip_power = st.checkbox("Skip power for lowly expressed genes", value=False)
            use_simulated = st.checkbox("Use simulated power for eQTLs", value=False)

    rangeX = np.round(np.linspace(rangeX_min, rangeX_max, steps)).astype(int)
    rangeY = np.round(np.linspace(rangeY_min[0], rangeY_max[0], steps)).astype(int)

    selected_pair = parameter_grid

    if selected_pair == "samples - cells per sample":
        sample_range = rangeX
        cells_range = rangeY
        read_range = None
    elif selected_pair == "samples - reads per cell":
        sample_range = rangeX
        cells_range = None
        read_range = rangeY
    else:  # "cells per sample - reads per cell"
        sample_range = None
        cells_range = rangeX
        read_range = rangeY
    
    args = {
        "totalBudget" : total_budget,
        "type" : study_type,
        "ct" : celltype, 
        "ct.freq" : ct_freq_slider,
        "costKit" : cost_10x_kit,
        "costFlowCell" : cost_flow_cell,
        "readsPerFlowcell" : reads_per_flow_cell,
        "ref.study.name" : ref_study,
        "cellsPerLane" : cells_per_lane,
        "nSamplesRange" : sample_range.tolist() if sample_range is not None else None,
        "nCellsRange" : cells_range.tolist() if cells_range is not None else None,
        "readDepthRange" : read_range.tolist() if read_range is not None else None,
        "mappingEfficiency" : mapping_efficiency,
        "multipletRate" : multiplet_rate,
        "multipletFactor" : multiplet_factor,
        "min.UMI.counts" : min_num_UMI_per_gene,
        "perc.indiv.expr" : fraction_of_indiv,
        "samplingMethod" : "quantiles",
        "sign.threshold" : p_value,
        "MTmethod" : multiple_testing_method,
        "useSimulatedPower" : use_simulated,
        "speedPowerCalc" : skip_power,
        "indepSNPs" : indepsnps,
        "ssize.ratio.de" : sample_size_ratio_slider,
        "reactionsPerKit" : reactions_per_kit
    }

    args = json_safe(args)
    
    if st.button("Run analysis"):
        try:
            args_json = json.dumps(args)

            logging.debug(f"JSON string: {args_json}")

            with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.json') as temp_file:
                json.dump(args, temp_file)
                temp_file_path = temp_file.name

            result = subprocess.run(['Rscript', 'scpower_collector.R', temp_file_path], capture_output=True, text=True)

            logging.info(f"R script stdout: {result.stdout}")
            if result.stderr:
                logging.error(f"R script stderr: {result.stderr}")

            # Remove the temporary file
            os.unlink(temp_file_path)

            # Check if we have valid output
            if not result.stdout.strip():
                st.error("The R script produced no output. Please check the logs for more information.")
                return

            try:
                st.session_state.scatter_data = json.loads(result.stdout)
                st.session_state.influence_data = json.loads(result.stdout)
                
                st.markdown("<br>", unsafe_allow_html=True)

                # data shown as json as well
                if isinstance(st.session_state.scatter_data, list):
                    st.write(f"Data in json format ({len(st.session_state.scatter_data)} items):")
                st.json(st.session_state.scatter_data, expanded=False)

                st.markdown("<br>", unsafe_allow_html=True)

                st.markdown("""
                <div class="hover-text">
                    <h3>Scatter Plot</h3>
                    <div class="hover-content">
                        <p>Detection power depending on <em>cells per individual</em>, <em>read depth</em> and <em>sample size</em>.</p>
                        <p><strong>How to use this scatter plot:</strong></p>
                        <ul style="padding-left: 20px;">
                            <li>Select the variables for X-axis, Y-axis, and Size from the dropdowns below.</li>
                            <li>The plot will update automatically based on your selections.</li>
                            <li>Use the plot tools to zoom, pan, or save the image.</li>
                        </ul>
                        <p><em>Tip: Try different combinations to discover interesting patterns in your data!</em></p>
                    </div>
                </div>
                """, unsafe_allow_html=True)

                keys = sorted(st.session_state.scatter_data[0].keys())

                x_axis = st.selectbox("Select X-axis", options=keys, index=keys.index("sampleSize"))
                y_axis = st.selectbox("Select Y-axis", options=keys, index=keys.index("totalCells"))
                size_axis = st.selectbox("Select Size-axis", options=keys, index=keys.index("Detection.power"))

                fig = create_scatter_plot(st.session_state.scatter_data, x_axis, y_axis, size_axis)
                if fig is not None:
                    st.plotly_chart(fig)
                    st.session_state.success_message.empty() # clear the success messages shown in the UI

                # Add the new influence plot
                if st.session_state.influence_data is not None:

                    st.markdown("""
                    <div class="hover-text">
                        <h3>Influence Plot</h3>
                        <div class="hover-content">
                            <ul>
                                <li>The overall detection power is the result of expression probability (probability that the DE/eQTL genes are detected) and DE power (probability that the DE/eQTL genes are found significant).</p>
                                <li>The plots show the influence of the y axis (left) and x axis (right) parameter of the upper plot onto the power of the selected study, while keeping the second parameter constant.</p>
                                <li>The dashed lines shows the location of the selected study.</p>
                            </ul>
                        </div>
                    </div>
                    """, unsafe_allow_html=True)

                    parameter_vector = ["sc", 1000, 100, 200, 400000000, "eqtl"]
                    fig = create_influence_plot(st.session_state.influence_data, parameter_vector)
                    if fig is not None:
                        st.plotly_chart(fig)
                else:
                    st.warning("No influence data available. Please check your data source.")
            
            except json.JSONDecodeError as e:
                st.error(f"Failed to parse R script output as JSON. Error: {str(e)}")
                st.code(result.stdout)  # Show the raw output for debugging
                logging.error(f"JSON parsing error: {str(e)}")
                logging.error(f"Raw output: {result.stdout}")
                return
            
        except Exception as e:
            st.error(f"An error occurred during analysis: {str(e)}")
            logging.exception("Error in perform_analysis")
            return

def main():
    st.set_page_config(initial_sidebar_state="collapsed")
    
    if 'page' not in st.session_state:
        st.session_state.page = "Home"

    st.sidebar.title("Navigation")
    pages = ["Home", "Description", "Tutorial", "Detect DE/eQTL Genes", "License Statement"]
    page = st.sidebar.radio("", pages, index=pages.index(st.session_state.page))

    if page != st.session_state.page:
        st.session_state.page = page
        st.rerun()

    if st.session_state.page == "Home":
        show_home_page()
    elif st.session_state.page == "Description":
        show_description_page()
    elif st.session_state.page == "Tutorial":
        show_tutorial_page()
    elif st.session_state.page == "Detect DE/eQTL Genes":
        perform_analysis()
    elif st.session_state.page == "License Statement":
        show_license_page()      

if __name__ == "__main__":
    main()