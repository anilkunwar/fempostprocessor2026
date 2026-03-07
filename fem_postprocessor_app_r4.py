import streamlit as st
import meshio
import numpy as np
import tempfile
import os
import sys
from pathlib import Path
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import json
import base64
from io import BytesIO, StringIO
import warnings
import re
import math
from datetime import datetime
import pandas as pd
from collections import defaultdict
warnings.filterwarnings('ignore')

# -----------------------------------------------------------------------------
# Page Configuration
# -----------------------------------------------------------------------------
st.set_page_config(
    page_title="MOOSE Exodus Viewer",
    page_icon="🦌",
    layout="wide",
    initial_sidebar_state="expanded",
    menu_items={
        'Get Help': 'https://mooseframework.inl.gov',
        'Report a bug': 'https://github.com/idaholab/moose/issues',
        'About': "MOOSE Exodus Viewer v3.0\nBuilt with Streamlit + Plotly + Meshio + NetCDF4"
    }
)

# -----------------------------------------------------------------------------
# Custom CSS for Better UI
# -----------------------------------------------------------------------------
st.markdown("""
<style>
.main-header {
    font-size: 2.5rem;
    font-weight: 700;
    color: #1f77b4;
    text-align: center;
    padding: 1rem 0;
    border-bottom: 3px solid #1f77b4;
    margin-bottom: 1.5rem;
}
.metric-card {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 10px;
    padding: 1rem;
    color: white;
    text-align: center;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}
.metric-value {
    font-size: 2rem;
    font-weight: bold;
}
.metric-label {
    font-size: 0.9rem;
    opacity: 0.9;
}
.download-btn {
    width: 100%;
    margin: 0.25rem 0;
}
.success-box {
    background-color: #d4edda;
    border: 1px solid #c3e6cb;
    border-radius: 5px;
    padding: 1rem;
    margin: 0.5rem 0;
}
.warning-box {
    background-color: #fff3cd;
    border: 1px solid #ffeaa7;
    border-radius: 5px;
    padding: 1rem;
    margin: 0.5rem 0;
}
.error-box {
    background-color: #f8d7da;
    border: 1px solid #f5c6cb;
    border-radius: 5px;
    padding: 1rem;
    margin: 0.5rem 0;
}
div[data-testid="stExpander"] {
    border: 1px solid #e0e0e0;
    border-radius: 8px;
}
pre {
    max-height: 400px;
    overflow-y: auto;
}
</style>
""", unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# Export Formats - VERIFIED meshio supported formats only
# -----------------------------------------------------------------------------
SUPPORTED_EXPORT_FORMATS = {
    'vtu': {
        'name': 'VTU (Unstructured Grid)',
        'ext': '.vtu',
        'mime': 'application/xml',
        'desc': 'Full 3D mesh with all variables (RECOMMENDED for ParaView)',
        'surface_only': False
    },
    'vtk': {
        'name': 'VTK (Legacy)',
        'ext': '.vtk',
        'mime': 'text/plain',
        'desc': 'Legacy VTK format (widely compatible)',
        'surface_only': False
    },
    'stl': {
        'name': 'STL (Surface)',
        'ext': '.stl',
        'mime': 'application/sla',
        'desc': 'Surface mesh for CAD/3D printing (no scalar data)',
        'surface_only': True
    },
    'ply': {
        'name': 'PLY (Polygon)',
        'ext': '.ply',
        'mime': 'application/octet-stream',
        'desc': 'Surface with vertex colors/data (good for visualization)',
        'surface_only': True
    },
    'xdmf': {
        'name': 'XDMF (Large Data)',
        'ext': '.xdmf',
        'mime': 'application/xml',
        'desc': 'XDMF for large datasets (requires h5py)',
        'surface_only': False,
        'requires': ['h5py']
    },
    'exodus': {
        'name': 'Exodus (MOOSE Native)',
        'ext': '.e',
        'mime': 'application/octet-stream',
        'desc': 'Native MOOSE format (for re-import)',
        'surface_only': False
    },
}

# -----------------------------------------------------------------------------
# Helper Functions - File Discovery
# -----------------------------------------------------------------------------
def find_exodus_files(search_dir, recursive=True):
    """
    Recursively find all Exodus files in the given directory.
    Args:
        search_dir: Directory path to search
        recursive: Whether to search subdirectories
    Returns:
        list: Sorted list of file paths
    """
    exodus_extensions = ['.e', '.exo', '.exodus', '.out', '.ex2', '.e-s001', '.e-s002']
    exodus_files = []
    if not os.path.exists(search_dir):
        return exodus_files
    try:
        if recursive:
            for root, dirs, files in os.walk(search_dir):
                dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['__pycache__', 'node_modules', '.git']]
                for file in files:
                    if file.startswith('.'):
                        continue
                    file_ext = os.path.splitext(file)[1].lower()
                    if file_ext in exodus_extensions or re.match(r'\.e-s\d+$', file_ext):
                        full_path = os.path.join(root, file)
                        exodus_files.append(full_path)
        else:
            for file in os.listdir(search_dir):
                if file.startswith('.'):
                    continue
                file_ext = os.path.splitext(file)[1].lower()
                if file_ext in exodus_extensions or re.match(r'\.e-s\d+$', file_ext):
                    full_path = os.path.join(search_dir, file)
                    exodus_files.append(full_path)
    except PermissionError as e:
        st.warning(f"Permission denied accessing: {search_dir}")
    except Exception as e:
        st.warning(f"Error scanning directory: {e}")
    exodus_files.sort(key=lambda x: (os.path.dirname(x), os.path.basename(x).lower()))
    return exodus_files

def get_file_display_name(file_path, base_dir):
    """Creates a user-friendly display name showing relative path."""
    try:
        rel_path = os.path.relpath(file_path, base_dir)
        if os.path.dirname(rel_path):
            return f"📁 {rel_path}"
        return f"📄 {os.path.basename(file_path)}"
    except ValueError:
        return f"📄 {os.path.basename(file_path)}"
    except Exception:
        return os.path.basename(file_path)

def get_file_size_mb(file_path):
    """Get file size in MB with error handling."""
    try:
        size_bytes = os.path.getsize(file_path)
        return size_bytes / (1024 * 1024)
    except OSError:
        return 0

def format_file_size(size_mb):
    """Format file size with appropriate units."""
    if size_mb < 1:
        return f"{size_mb * 1024:.1f} KB"
    elif size_mb < 100:
        return f"{size_mb:.2f} MB"
    else:
        return f"{size_mb:.1f} MB"

# -----------------------------------------------------------------------------
# Helper Functions - NetCDF4 Time-Step Reading (NEW)
# -----------------------------------------------------------------------------
def read_exodus_all_timesteps(file_path):
    """
    Read ALL time steps from an Exodus file using netCDF4 directly.
    This bypasses meshio's limitation of only reading the last time step.
    
    Returns:
        dict with keys:
            - 'mesh': meshio mesh with topology (from first timestep)
            - 'time_values': array of time values
            - 'n_times': number of time steps
            - 'point_data_all': dict of {var_name: (n_times, n_points, [components])}
            - 'cell_data_all': dict of {var_name: (n_times, n_cells, [components])}
            - 'point_vars': list of point variable names
            - 'cell_vars': list of cell variable names
    """
    try:
        from netCDF4 import Dataset
    except ImportError:
        st.error("netCDF4 library not installed. Please install with: pip install netCDF4")
        return None
    
    if not os.path.exists(file_path):
        st.error(f"File not found: {file_path}")
        return None
    
    try:
        with st.spinner(f"Reading all time steps from {os.path.basename(file_path)}..."):
            with Dataset(file_path, 'r') as nc:
                # Read mesh topology (static - same for all time steps)
                mesh = meshio.read(file_path)
                
                # Get time values
                time_values = None
                n_times = 1
                if 'time_whole' in nc.variables:
                    time_values = nc.variables['time_whole'][:]
                    n_times = len(time_values)
                elif 'time' in nc.variables:
                    time_values = nc.variables['time'][:]
                    n_times = len(time_values)
                else:
                    # Check for time dimension
                    if 'time' in nc.dimensions:
                        n_times = nc.dimensions['time'].size
                    elif 'num_time_steps' in nc.dimensions:
                        n_times = nc.dimensions['num_time_steps'].size
                
                # Initialize data containers
                point_data_all = {}
                cell_data_all = {}
                point_vars = []
                cell_vars = []
                
                # Read nodal (point) variables
                if 'num_nod_var' in nc.dimensions:
                    num_nod_vars = nc.dimensions['num_nod_var'].size
                    for k in range(num_nod_vars):
                        var_name_key = f'name_nod_var{k+1}'
                        if var_name_key in nc.variables:
                            var_name = nc.variables[var_name_key][:]
                            if isinstance(var_name, np.ndarray):
                                var_name = var_name.tobytes().decode('utf-8', errors='ignore').strip('\x00')
                            else:
                                var_name = str(var_name).strip()
                            
                            if var_name:
                                vals_var = f'vals_nod_var{k+1}'
                                if vals_var in nc.variables:
                                    data = nc.variables[vals_var][:]
                                    # Shape: (time, nodes) or (time, nodes, components)
                                    point_data_all[var_name] = data
                                    point_vars.append(var_name)
                
                # Read elemental (cell) variables
                if 'num_elem_var' in nc.dimensions:
                    num_elem_vars = nc.dimensions['num_elem_var'].size
                    for k in range(num_elem_vars):
                        var_name_key = f'name_elem_var{k+1}'
                        if var_name_key in nc.variables:
                            var_name = nc.variables[var_name_key][:]
                            if isinstance(var_name, np.ndarray):
                                var_name = var_name.tobytes().decode('utf-8', errors='ignore').strip('\x00')
                            else:
                                var_name = str(var_name).strip()
                            
                            if var_name:
                                vals_var = f'vals_elem_var{k+1}'
                                if vals_var in nc.variables:
                                    data = nc.variables[vals_var][:]
                                    cell_data_all[var_name] = data
                                    cell_vars.append(var_name)
                
                # Also check meshio's point_data for any additional variables
                if mesh.point_data:
                    for var_name, data in mesh.point_data.items():
                        if var_name not in point_data_all:
                            # meshio only has last timestep, expand to match n_times
                            if data.ndim == 1:
                                expanded = np.tile(data, (n_times, 1))
                            else:
                                expanded = np.tile(data, (n_times, 1, 1))
                            point_data_all[var_name] = expanded
                            if var_name not in point_vars:
                                point_vars.append(var_name)
                
                if mesh.cell_data:
                    for var_name, data_list in mesh.cell_data.items():
                        if var_name not in cell_data_all:
                            # meshio only has last timestep
                            if isinstance(data_list, list) and len(data_list) > 0:
                                data = np.concatenate([np.asarray(d) for d in data_list if d is not None])
                            else:
                                data = np.asarray(data_list)
                            if data.ndim == 1:
                                expanded = np.tile(data, (n_times, 1))
                            else:
                                expanded = np.tile(data, (n_times, 1, 1))
                            cell_data_all[var_name] = expanded
                            if var_name not in cell_vars:
                                cell_vars.append(var_name)
                
                return {
                    'mesh': mesh,
                    'time_values': time_values,
                    'n_times': n_times,
                    'point_data_all': point_data_all,
                    'cell_data_all': cell_data_all,
                    'point_vars': sorted(point_vars),
                    'cell_vars': sorted(cell_vars)
                }
    
    except Exception as e:
        st.error(f"Error reading Exodus file with netCDF4: {type(e).__name__}: {str(e)}")
        with st.expander("Technical Details", expanded=False):
            st.code(f"File: {file_path}\nError: {type(e).__name__}: {str(e)}", language="text")
        return None

def load_exodus_data(file_path, time_step=None):
    """
    Read an Exodus file using meshio (for topology) and netCDF4 (for all time data).
    Args:
        file_path: Path to Exodus file
        time_step: Optional time step index to load (for single-step loading)
    Returns:
        dict with mesh data or None on error
    """
    return read_exodus_all_timesteps(file_path)

# -----------------------------------------------------------------------------
# Helper Functions - Mesh Loading & Analysis
# -----------------------------------------------------------------------------
def analyze_mesh(mesh_data, time_step=0):
    """
    Analyze mesh and return statistics dictionary.
    Args:
        mesh_data: dict from read_exodus_all_timesteps
        time_step: Which time step to analyze (for variable ranges)
    Returns:
        stats dict
    """
    if mesh_data is None:
        return {}
    
    mesh = mesh_data.get('mesh')
    if mesh is None:
        return {}
    
    stats = {
        'n_points': len(mesh.points) if mesh.points is not None else 0,
        'n_cells': 0,
        'cell_types': {},
        'dimensions': None,
        'bounds': None,
        'point_vars': mesh_data.get('point_vars', []),
        'cell_vars': mesh_data.get('cell_vars', []),
        'field_info': {},
        'n_times': mesh_data.get('n_times', 1),
        'time_values': mesh_data.get('time_values')
    }
    
    if mesh.cells:
        for cell_block in mesh.cells:
            if cell_block and cell_block.data is not None:
                cell_type = cell_block.type or 'unknown'
                n_cells = len(cell_block.data)
                stats['n_cells'] += n_cells
                stats['cell_types'][cell_type] = stats['cell_types'].get(cell_type, 0) + n_cells
    
    if mesh.points is not None and len(mesh.points) > 0:
        points = np.asarray(mesh.points)
        stats['dimensions'] = points.shape[1] if points.ndim > 1 else 1
        stats['bounds'] = {
            'x': (float(np.min(points[:, 0])), float(np.max(points[:, 0]))),
            'y': (float(np.min(points[:, 1])), float(np.max(points[:, 1]))) if points.shape[1] > 1 else None,
            'z': (float(np.min(points[:, 2])), float(np.max(points[:, 2]))) if points.shape[1] > 2 else None,
        }
    
    # Compute variable ranges for the specified time step
    point_data_all = mesh_data.get('point_data_all', {})
    cell_data_all = mesh_data.get('cell_data_all', {})
    
    for var_name in stats['point_vars']:
        if var_name in point_data_all:
            data = point_data_all[var_name]
            try:
                if data.ndim >= 2:
                    if time_step < data.shape[0]:
                        ts_data = data[time_step]
                    else:
                        ts_data = data[-1]
                    
                    if ts_data.ndim > 1:
                        # Vector variable - compute magnitude
                        mag = np.linalg.norm(ts_data, axis=1)
                        global_min = float(np.min(mag))
                        global_max = float(np.max(mag))
                        shape = ts_data.shape[1:]
                    else:
                        global_min = float(np.min(ts_data))
                        global_max = float(np.max(ts_data))
                        shape = ()
                    
                    stats['field_info'][var_name] = {
                        'location': 'point',
                        'shape': shape,
                        'dtype': str(ts_data.dtype),
                        'range': (global_min, global_max),
                        'n_times': data.shape[0] if data.ndim >= 2 else 1
                    }
            except Exception:
                stats['field_info'][var_name] = {}
    
    for var_name in stats['cell_vars']:
        if var_name in cell_data_all:
            data = cell_data_all[var_name]
            try:
                if data.ndim >= 2:
                    if time_step < data.shape[0]:
                        ts_data = data[time_step]
                    else:
                        ts_data = data[-1]
                    
                    if ts_data.ndim > 1:
                        mag = np.linalg.norm(ts_data, axis=1)
                        global_min = float(np.min(mag))
                        global_max = float(np.max(mag))
                        shape = ts_data.shape[1:]
                    else:
                        global_min = float(np.min(ts_data))
                        global_max = float(np.max(ts_data))
                        shape = ()
                    
                    stats['field_info'][var_name] = {
                        'location': 'cell',
                        'shape': shape,
                        'dtype': str(ts_data.dtype),
                        'range': (global_min, global_max),
                        'n_times': data.shape[0] if data.ndim >= 2 else 1
                    }
            except Exception:
                stats['field_info'][var_name] = {}
    
    return stats

# -----------------------------------------------------------------------------
# Helper Functions - Mesh Merging
# -----------------------------------------------------------------------------
def merge_meshes(meshes_data_list):
    """
    Merge a list of mesh data dicts (from parallel subdomains) into a single mesh.
    Assumes all meshes have the same variables and cell types.
    """
    if not meshes_data_list:
        return None
    if len(meshes_data_list) == 1:
        return meshes_data_list[0]
    
    # Merge topology using meshio meshes
    meshio_meshes = [md['mesh'] for md in meshes_data_list if md.get('mesh')]
    merged_mesh = merge_meshio_meshes(meshio_meshes)
    
    if merged_mesh is None:
        return None
    
    # Merge time data
    n_times = max(md.get('n_times', 1) for md in meshes_data_list)
    time_values = None
    for md in meshes_data_list:
        if md.get('time_values') is not None:
            time_values = md['time_values']
            break
    
    # Merge point data
    point_data_all = {}
    point_vars = set()
    for md in meshes_data_list:
        for var, data in md.get('point_data_all', {}).items():
            point_vars.add(var)
            if var not in point_data_all:
                point_data_all[var] = []
            point_data_all[var].append(data)
    
    # Merge cell data
    cell_data_all = {}
    cell_vars = set()
    for md in meshes_data_list:
        for var, data in md.get('cell_data_all', {}).items():
            cell_vars.add(var)
            if var not in cell_data_all:
                cell_data_all[var] = []
            cell_data_all[var].append(data)
    
    # Concatenate along node/cell axis (not time axis)
    for var in point_vars:
        if var in point_data_all and len(point_data_all[var]) > 1:
            # Each entry is (n_times, n_nodes, [components])
            # Concatenate along n_nodes axis (axis=1)
            point_data_all[var] = np.concatenate(point_data_all[var], axis=1)
        elif var in point_data_all:
            point_data_all[var] = point_data_all[var][0]
    
    for var in cell_vars:
        if var in cell_data_all and len(cell_data_all[var]) > 1:
            cell_data_all[var] = np.concatenate(cell_data_all[var], axis=1)
        elif var in cell_data_all:
            cell_data_all[var] = cell_data_all[var][0]
    
    return {
        'mesh': merged_mesh,
        'time_values': time_values,
        'n_times': n_times,
        'point_data_all': point_data_all,
        'cell_data_all': cell_data_all,
        'point_vars': sorted(list(point_vars)),
        'cell_vars': sorted(list(cell_vars))
    }

def merge_meshio_meshes(meshes):
    """Merge meshio Mesh objects (topology only)."""
    if not meshes:
        return None
    if len(meshes) == 1:
        return meshes[0]
    
    all_points = []
    cells_by_type = defaultdict(list)
    offset = 0
    
    for mesh in meshes:
        all_points.append(mesh.points)
        for cell_block in mesh.cells:
            typ = cell_block.type
            shifted_data = cell_block.data + offset
            cells_by_type[typ].append(shifted_data)
        offset += len(mesh.points)
    
    points = np.vstack(all_points)
    cells = []
    for typ in sorted(cells_by_type.keys()):
        data = np.concatenate(cells_by_type[typ], axis=0)
        cells.append(meshio.CellBlock(typ, data))
    
    return meshio.Mesh(points=points, cells=cells)

# -----------------------------------------------------------------------------
# Helper Functions - Surface Extraction for Plotly
# -----------------------------------------------------------------------------
def extract_mesh_surfaces(meshio_mesh, cell_types_filter=None):
    """
    Extract surface triangles from mesh for Plotly visualization.
    Args:
        meshio_mesh: meshio Mesh object
        cell_types_filter: Optional list of cell types to include
    Returns:
        tuple: (points, faces, face_cell_map) or (None, None, None)
    """
    if meshio_mesh is None:
        return None, None, None
    
    points = meshio_mesh.points
    if points is None or len(points) == 0:
        return None, None, None
    
    faces = []
    face_cell_map = []
    
    if not meshio_mesh.cells:
        return None, None, None
    
    for block_idx, cell_block in enumerate(meshio_mesh.cells):
        if cell_block is None or cell_block.data is None:
            continue
        cell_type = cell_block.type
        cells = cell_block.data
        
        if cells is None or len(cells) == 0:
            continue
        
        if cell_types_filter and cell_type not in cell_types_filter:
            continue
        
        try:
            if cell_type in ['tetra', 'tetrahedron']:
                for cell_idx, cell in enumerate(cells):
                    if len(cell) >= 4:
                        tetra_faces = [
                            [cell[0], cell[1], cell[2]],
                            [cell[0], cell[1], cell[3]],
                            [cell[0], cell[2], cell[3]],
                            [cell[1], cell[2], cell[3]]
                        ]
                        for face in tetra_faces:
                            faces.append(face)
                            face_cell_map.append((block_idx, cell_idx))
            
            elif cell_type in ['hexahedron', 'hex', 'hexa', 'hexahedron20', 'hexahedron27']:
                for cell_idx, cell in enumerate(cells):
                    if len(cell) >= 8:
                        hex_faces = [
                            [cell[0], cell[1], cell[2], cell[3]],
                            [cell[4], cell[5], cell[6], cell[7]],
                            [cell[0], cell[1], cell[5], cell[4]],
                            [cell[2], cell[3], cell[7], cell[6]],
                            [cell[0], cell[3], cell[7], cell[4]],
                            [cell[1], cell[2], cell[6], cell[5]]
                        ]
                        for quad in hex_faces:
                            faces.append([quad[0], quad[1], quad[2]])
                            faces.append([quad[0], quad[2], quad[3]])
                            face_cell_map.extend([(block_idx, cell_idx), (block_idx, cell_idx)])
            
            elif cell_type in ['triangle', 'tri', 'triangle6', 'triangle7']:
                for cell_idx, cell in enumerate(cells):
                    if len(cell) >= 3:
                        faces.append([cell[0], cell[1], cell[2]])
                        face_cell_map.append((block_idx, cell_idx))
            
            elif cell_type in ['quad', 'quadrilateral', 'quad8', 'quad9']:
                for cell_idx, cell in enumerate(cells):
                    if len(cell) >= 4:
                        faces.append([cell[0], cell[1], cell[2]])
                        faces.append([cell[0], cell[2], cell[3]])
                        face_cell_map.extend([(block_idx, cell_idx), (block_idx, cell_idx)])
            
            elif cell_type in ['wedge', 'triangular_prism', 'wedge15', 'wedge18']:
                for cell_idx, cell in enumerate(cells):
                    if len(cell) >= 6:
                        faces.append([cell[0], cell[1], cell[2]])
                        faces.append([cell[3], cell[5], cell[4]])
                        face_cell_map.extend([(block_idx, cell_idx), (block_idx, cell_idx)])
                        wedge_faces = [
                            [cell[0], cell[1], cell[4], cell[3]],
                            [cell[1], cell[2], cell[5], cell[4]],
                            [cell[2], cell[0], cell[3], cell[5]]
                        ]
                        for quad in wedge_faces:
                            faces.append([quad[0], quad[1], quad[2]])
                            faces.append([quad[0], quad[2], quad[3]])
                            face_cell_map.extend([(block_idx, cell_idx), (block_idx, cell_idx)])
            
            elif cell_type in ['pyramid', 'pyra', 'pyramid13']:
                for cell_idx, cell in enumerate(cells):
                    if len(cell) >= 5:
                        faces.append([cell[0], cell[1], cell[2]])
                        faces.append([cell[0], cell[2], cell[3]])
                        face_cell_map.extend([(block_idx, cell_idx), (block_idx, cell_idx)])
                        for tri in [[cell[0], cell[1], cell[4]],
                                   [cell[1], cell[2], cell[4]],
                                   [cell[2], cell[3], cell[4]],
                                   [cell[3], cell[0], cell[4]]]:
                            faces.append(tri)
                            face_cell_map.append((block_idx, cell_idx))
            
            elif cell_type in ['line', 'line2', 'line3', 'vertex']:
                continue
            
            else:
                if not hasattr(extract_mesh_surfaces, '_logged_types'):
                    extract_mesh_surfaces._logged_types = set()
                if cell_type not in extract_mesh_surfaces._logged_types:
                    extract_mesh_surfaces._logged_types.add(cell_type)
        
        except (IndexError, TypeError, ValueError, KeyError) as e:
            continue
    
    if len(faces) == 0:
        return None, None, None
    
    try:
        faces = np.array(faces, dtype=np.int32)
        if faces.ndim != 2 or faces.shape[1] != 3:
            return None, None, None
        
        # Remove duplicate faces (internal faces)
        sorted_faces = np.sort(faces, axis=1)
        unique_faces, unique_indices = np.unique(sorted_faces, axis=0, return_index=True)
        faces = faces[unique_indices]
        
        return points, faces, face_cell_map
    except Exception as e:
        return None, None, None

# -----------------------------------------------------------------------------
# Helper Functions - Plotly Visualization
# -----------------------------------------------------------------------------
def create_plotly_mesh(points, faces, values=None, color_map='Viridis',
                       opacity=0.9, show_edges=False, title="Mesh",
                       show_scalar_bar=True, camera_preset='isometric'):
    """
    Create a Plotly 3D mesh visualization with extensive customization.
    """
    if points is None or faces is None or len(points) == 0 or len(faces) == 0:
        fig = go.Figure()
        fig.add_annotation(
            text="No mesh data available for visualization",
            xref="paper", yref="paper", x=0.5, y=0.5,
            showarrow=False, font=dict(size=16, color="gray")
        )
        fig.update_layout(
            scene=dict(xaxis_title='X', yaxis_title='Y', zaxis_title='Z', aspectmode='data'),
            height=600, title=title, template='plotly_white'
        )
        return fig
    
    try:
        i, j, k = faces[:, 0], faces[:, 1], faces[:, 2]
    except (IndexError, TypeError):
        return create_plotly_mesh(None, None, None, title=title)
    
    intensity = None
    colorscale = None
    showscale = False
    colorbar = None
    
    if values is not None and len(values) > 0:
        try:
            values = np.asarray(values).flatten()
            if len(values) == len(faces):
                intensity = values
                colorscale = color_map
                showscale = show_scalar_bar
                if show_scalar_bar:
                    colorbar = dict(
                        title=dict(text=title, font=dict(size=11)),
                        thickness=20,
                        len=0.6,
                        x=0.95,
                        y=0.5
                    )
        except Exception:
            pass
    
    mesh_trace = go.Mesh3d(
        x=points[:, 0], y=points[:, 1], z=points[:, 2],
        i=i, j=j, k=k,
        intensity=intensity,
        colorscale=colorscale,
        opacity=opacity,
        showscale=showscale,
        colorbar=colorbar,
        flatshading=True,
        lighting=dict(ambient=0.5, diffuse=0.8, roughness=0.4, specular=0.3),
        lightposition=dict(x=100, y=100, z=100),
        name='Mesh',
        hovertemplate=(
            "<b>Face</b><br>" +
            "X: %{x:.3f}<br>" +
            "Y: %{y:.3f}<br>" +
            "Z: %{z:.3f}<br>" +
            (f"Value: %{{intensity:.4g}}<br>" if intensity is not None else "") +
            "<extra></extra>"
        )
    )
    
    fig = go.Figure(data=[mesh_trace])
    
    if show_edges and len(faces) < 30000:
        edge_x, edge_y, edge_z = [], [], []
        for face in faces:
            for idx1, idx2 in [(0,1), (1,2), (2,0)]:
                try:
                    p1, p2 = points[face[idx1]], points[face[idx2]]
                    edge_x.extend([p1[0], p2[0], None])
                    edge_y.extend([p1[1], p2[1], None])
                    edge_z.extend([p1[2], p2[2], None])
                except (IndexError, TypeError):
                    continue
        if edge_x:
            fig.add_trace(go.Scatter3d(
                x=edge_x, y=edge_y, z=edge_z,
                mode='lines',
                line=dict(color='black', width=0.5),
                name='Edges',
                opacity=0.5,
                showlegend=False,
                hoverinfo='skip'
            ))
    
    camera_presets = {
        'isometric': dict(eye=dict(x=1.5, y=1.5, z=1.5)),
        'top': dict(eye=dict(x=0, y=0, z=2.5)),
        'front': dict(eye=dict(x=0, y=2.5, z=0)),
        'side': dict(eye=dict(x=2.5, y=0, z=0)),
        'corner': dict(eye=dict(x=2, y=2, z=1)),
    }
    camera = camera_presets.get(camera_preset, camera_presets['isometric'])
    
    fig.update_layout(
        scene=dict(
            xaxis_title='X', yaxis_title='Y', zaxis_title='Z',
            aspectmode='data',
            camera=camera,
            bgcolor='white'
        ),
        height=600,
        margin=dict(l=0, r=0, t=50, b=0),
        title=dict(text=title, x=0.5, xanchor='center', font=dict(size=18)),
        hovermode='closest',
        template='plotly_white',
        paper_bgcolor='white',
        plot_bgcolor='white'
    )
    
    return fig

def create_variable_histogram(values, var_name, nbins=50):
    """Create a histogram of variable values."""
    if values is None or len(values) == 0:
        return None
    try:
        values = np.asarray(values).flatten()
        values = values[np.isfinite(values)]
        if len(values) == 0:
            return None
        fig = go.Figure(data=[
            go.Histogram(
                x=values,
                nbinsx=nbins,
                marker_color='#667eea',
                opacity=0.7,
                name=var_name
            )
        ])
        fig.update_layout(
            title=f"Distribution: {var_name}",
            xaxis_title="Value",
            yaxis_title="Count",
            height=300,
            margin=dict(l=40, r=20, t=40, b=40),
            template='plotly_white'
        )
        return fig
    except Exception:
        return None

def create_time_series_plot(mesh_data, variable_base, time_step_current):
    """Create a time series plot showing variable evolution over all time steps."""
    if mesh_data is None or variable_base is None:
        return None
    
    point_data_all = mesh_data.get('point_data_all', {})
    cell_data_all = mesh_data.get('cell_data_all', {})
    time_values = mesh_data.get('time_values')
    n_times = mesh_data.get('n_times', 1)
    
    if n_times <= 1:
        return None
    
    # Find the variable data
    data = None
    location = None
    if variable_base in point_data_all:
        data = point_data_all[variable_base]
        location = 'point'
    elif variable_base in cell_data_all:
        data = cell_data_all[variable_base]
        location = 'cell'
    
    if data is None:
        return None
    
    try:
        # Compute statistic per time step (mean, min, max)
        if data.ndim >= 2:
            time_stats = []
            for t in range(min(n_times, data.shape[0])):
                ts_data = data[t]
                if ts_data.ndim > 1:
                    ts_data = np.linalg.norm(ts_data, axis=1)
                time_stats.append({
                    'mean': float(np.mean(ts_data)),
                    'min': float(np.min(ts_data)),
                    'max': float(np.max(ts_data))
                })
            
            if time_values is None:
                time_values = np.arange(n_times)
            
            fig = go.Figure()
            fig.add_trace(go.Scatter(
                x=time_values[:len(time_stats)],
                y=[s['mean'] for s in time_stats],
                mode='lines+markers',
                name='Mean',
                line=dict(color='#1f77b4', width=2),
                marker=dict(size=6)
            ))
            fig.add_trace(go.Scatter(
                x=time_values[:len(time_stats)],
                y=[s['max'] for s in time_stats],
                mode='lines',
                name='Max',
                line=dict(color='#d62728', width=1, dash='dash')
            ))
            fig.add_trace(go.Scatter(
                x=time_values[:len(time_stats)],
                y=[s['min'] for s in time_stats],
                mode='lines',
                name='Min',
                line=dict(color='#2ca02c', width=1, dash='dash')
            ))
            
            # Mark current time step
            fig.add_vline(x=time_values[time_step_current] if time_step_current < len(time_values) else time_step_current,
                         line_dash="dot", line_color="gray",
                         annotation_text=f"Current: t={time_step_current}")
            
            fig.update_layout(
                title=f"Time Evolution: {variable_base}",
                xaxis_title="Time Step" if time_values is None else "Time",
                yaxis_title="Value",
                height=300,
                margin=dict(l=40, r=20, t=40, b=40),
                template='plotly_white',
                hovermode='x unified'
            )
            return fig
    except Exception:
        pass
    
    return None

# -----------------------------------------------------------------------------
# Helper Functions - Format Conversion for ParaView
# -----------------------------------------------------------------------------
def get_meshio_write_formats():
    """
    Dynamically get supported write formats from meshio.
    Returns set of format keys.
    """
    try:
        import meshio
        if hasattr(meshio, '_format_registry'):
            return set(meshio._format_registry.write.keys())
        elif hasattr(meshio, 'extension_to_filetype'):
            return set(meshio.extension_to_filetype.values())
        else:
            return {'vtu', 'vtk', 'stl', 'ply', 'xdmf', 'exodus'}
    except Exception:
        return {'vtu', 'vtk', 'stl', 'ply', 'xdmf', 'exodus'}

def convert_mesh_format(mesh_data, output_path, file_format, time_step=0):
    """
    Convert mesh to specified format using meshio.
    Args:
        mesh_data: dict from read_exodus_all_timesteps
        output_path: Path to write output file
        file_format: Format key (vtu, vtk, etc.)
        time_step: Which time step to export
    Returns:
        tuple: (success: bool, message: str, file_size_mb: float)
    """
    if mesh_data is None:
        return False, "No mesh data to export", 0
    
    mesh = mesh_data.get('mesh')
    if mesh is None:
        return False, "No mesh topology available", 0
    
    supported = get_meshio_write_formats()
    if file_format not in supported:
        return False, f"Format '{file_format}' not supported by meshio. Available: {sorted(supported)}", 0
    
    if file_format not in SUPPORTED_EXPORT_FORMATS:
        return False, f"Unknown format configuration: {file_format}", 0
    
    format_info = SUPPORTED_EXPORT_FORMATS[file_format]
    
    if 'requires' in format_info:
        for dep in format_info['requires']:
            try:
                __import__(dep)
            except ImportError:
                return False, f"{format_info['name']} requires '{dep}': pip install {dep}", 0
    
    try:
        # Create export mesh with data for specific time step
        export_mesh = meshio.Mesh(
            points=mesh.points,
            cells=mesh.cells
        )
        
        # Add point data for selected time step
        point_data_all = mesh_data.get('point_data_all', {})
        for var_name, data in point_data_all.items():
            try:
                if data.ndim >= 2 and time_step < data.shape[0]:
                    export_mesh.point_data[var_name] = data[time_step]
                elif data.ndim == 1:
                    export_mesh.point_data[var_name] = data
            except Exception:
                continue
        
        # Add cell data for selected time step
        cell_data_all = mesh_data.get('cell_data_all', {})
        for var_name, data in cell_data_all.items():
            try:
                if data.ndim >= 2 and time_step < data.shape[0]:
                    export_mesh.cell_data[var_name] = [data[time_step]]
                elif data.ndim == 1:
                    export_mesh.cell_data[var_name] = [data]
            except Exception:
                continue
        
        if format_info.get('surface_only', False):
            points, faces, _ = extract_mesh_surfaces(mesh)
            if points is None or faces is None or len(faces) == 0:
                return False, "Could not extract surface mesh for export", 0
            triangle_cells = meshio.CellBlock('triangle', faces)
            export_mesh = meshio.Mesh(points=points, cells=[triangle_cells])
            
            if file_format == 'ply' and export_mesh.point_data:
                scalar_point_data = {}
                for key, val in export_mesh.point_data.items():
                    try:
                        arr = np.asarray(val)
                        if arr.ndim == 1 or (arr.ndim == 2 and arr.shape[1] <= 3):
                            scalar_point_data[key] = arr
                    except Exception:
                        continue
                if scalar_point_data:
                    export_mesh.point_data = scalar_point_data
        
        meshio.write(output_path, export_mesh, file_format=file_format)
        
        if os.path.exists(output_path):
            size_mb = get_file_size_mb(output_path)
            if size_mb > 0:
                return True, f"Exported: {format_file_size(size_mb)}", size_mb
            return False, "Output file is empty", 0
        return False, "Failed to create output file", 0
    
    except ImportError as e:
        return False, f"Missing dependency: {e}", 0
    except Exception as e:
        return False, f"{type(e).__name__}: {str(e)[:200]}", 0

def export_variable_csv(mesh_data, variable_base, output_path, time_step=0):
    """Export variable data to CSV with coordinates for the specified timestep."""
    if mesh_data is None or not variable_base:
        return False, "No data to export"
    
    try:
        mesh = mesh_data.get('mesh')
        if mesh is None:
            return False, "No mesh available"
        
        point_data_all = mesh_data.get('point_data_all', {})
        cell_data_all = mesh_data.get('cell_data_all', {})
        
        # Determine location and get data
        location = None
        data = None
        
        if variable_base in point_data_all:
            data = point_data_all[variable_base]
            location = 'point'
        elif variable_base in cell_data_all:
            data = cell_data_all[variable_base]
            location = 'cell'
        
        if data is None:
            return False, f"Variable '{variable_base}' not found"
        
        # Extract time step
        if data.ndim >= 2 and time_step < data.shape[0]:
            data = data[time_step]
        
        if data.ndim > 1:
            if data.shape[1] <= 3:
                df = pd.DataFrame(data, columns=[f'{variable_base}_{i}' for i in range(data.shape[1])])
                df[f'{variable_base}_mag'] = np.linalg.norm(data, axis=1)
            else:
                df = pd.DataFrame(data)
                df.columns = [f'{variable_base}_{i}' for i in range(data.shape[1])]
        else:
            df = pd.DataFrame({variable_base: data})
        
        if location == 'point' and mesh.points is not None:
            coord_df = pd.DataFrame(mesh.points[:, :3], columns=['x', 'y', 'z'])
            df = pd.concat([coord_df, df], axis=1)
        
        df.insert(0, 'index', range(len(df)))
        df.to_csv(output_path, index=False)
        
        if os.path.exists(output_path) and os.path.getsize(output_path) > 0:
            return True, f"Exported {len(df)} rows"
        return False, "Empty output"
    
    except ImportError:
        return False, "pandas required: pip install pandas"
    except Exception as e:
        return False, f"{type(e).__name__}: {e}"

# -----------------------------------------------------------------------------
# Helper Functions - Data Processing
# -----------------------------------------------------------------------------
def get_variable_values(mesh_data, variable_base, faces, face_cell_map=None,
                        time_step=0):
    """
    Extract scalar values for a base variable at a given timestep, mapped to faces.
    Uses mesh_data to access time-dependent data.
    """
    if variable_base is None or faces is None or len(faces) == 0 or mesh_data is None:
        return None
    
    point_data_all = mesh_data.get('point_data_all', {})
    cell_data_all = mesh_data.get('cell_data_all', {})
    mesh = mesh_data.get('mesh')
    
    # Determine location and get data
    location = None
    data = None
    
    if variable_base in point_data_all:
        data = point_data_all[variable_base]
        location = 'point'
    elif variable_base in cell_data_all:
        data = cell_data_all[variable_base]
        location = 'cell'
    
    if data is None:
        return None
    
    # Extract time step
    if data.ndim >= 2 and time_step < data.shape[0]:
        data = data[time_step]
    elif data.ndim >= 2:
        data = data[-1]
    
    if location == 'point':
        point_values = np.asarray(data)
        # If vector, take magnitude
        if point_values.ndim > 1:
            point_values = np.linalg.norm(point_values, axis=1)
        try:
            face_values = np.mean(point_values[faces], axis=1)
            return face_values
        except (IndexError, TypeError, ValueError):
            return None
    
    elif location == 'cell':
        cell_values = np.asarray(data)
        if cell_values.ndim > 1:
            cell_values = np.linalg.norm(cell_values, axis=1)
        
        # Map cell values to faces
        if face_cell_map and len(face_cell_map) == len(faces):
            face_values = np.zeros(len(faces))
            for face_idx, (block_idx, cell_idx) in enumerate(face_cell_map):
                global_idx = 0
                for bi, cb in enumerate(mesh.cells):
                    if cb and cb.data is not None:
                        if bi < block_idx:
                            global_idx += len(cb.data)
                        elif bi == block_idx:
                            global_idx += cell_idx
                            break
                if 0 <= global_idx < len(cell_values):
                    face_values[face_idx] = cell_values[global_idx]
            return face_values
        
        total_cells = sum(len(cb.data) for cb in mesh.cells if cb and cb.data is not None)
        if total_cells > 0 and len(cell_values) == total_cells:
            faces_per_cell = max(1, len(faces) // total_cells)
            face_values = np.repeat(cell_values, faces_per_cell)
            if len(face_values) > len(faces):
                face_values = face_values[:len(faces)]
            elif len(face_values) < len(faces):
                face_values = np.pad(face_values, (0, len(faces) - len(face_values)), mode='edge')
            return face_values
    
    return None

# -----------------------------------------------------------------------------
# Main Application
# -----------------------------------------------------------------------------
def main():
    """Main application entry point."""
    st.markdown('<div class="main-header">🦌 MOOSE Exodus Output Viewer</div>', unsafe_allow_html=True)
    st.markdown("""
    **Visualize** MOOSE simulation results interactively in your browser.
    **Download** in ParaView-compatible formats for advanced post-processing.
    **Time-Series Support**: View all time steps with interactive sliders.
    """)
    
    app_dir = os.path.dirname(os.path.abspath(__file__))
    dataset_dir = os.path.join(app_dir, "dataset")
    
    # Initialize session state
    if 'selected_dir' not in st.session_state:
        st.session_state.selected_dir = None
    if 'mesh_data' not in st.session_state:
        st.session_state.mesh_data = None
    if 'mesh_stats' not in st.session_state:
        st.session_state.mesh_stats = None
    if 'cache_dir' not in st.session_state:
        st.session_state.cache_dir = tempfile.mkdtemp(prefix="moose_viewer_")
    if 'points' not in st.session_state:
        st.session_state.points = None
    if 'faces' not in st.session_state:
        st.session_state.faces = None
    if 'face_cell_map' not in st.session_state:
        st.session_state.face_cell_map = None
    if 'current_time_step' not in st.session_state:
        st.session_state.current_time_step = 0
    
    # Clear cache button
    if st.sidebar.button("Clear Cache", help="Clear loaded mesh data"):
        for key in ['mesh_data', 'mesh_stats', 'points', 'faces', 'face_cell_map',
                   'selected_dir', 'current_time_step']:
            st.session_state[key] = None
        st.rerun()
    
    with st.sidebar:
        st.header("1. Select Simulation Directory")
        
        # Find subdirectories in dataset/
        if not os.path.exists(dataset_dir):
            os.makedirs(dataset_dir, exist_ok=True)
            st.warning(f"Created 'dataset/' directory. Please place Exodus files in subdirectories.")
            st.stop()
        
        subdirs = [d for d in sorted(os.listdir(dataset_dir))
                  if os.path.isdir(os.path.join(dataset_dir, d))]
        
        if not subdirs:
            st.warning("No subdirectories found in 'dataset/' folder.")
            st.markdown(f"""
            **Create folder:** `{dataset_dir}`
            Place Exodus files in subdirectories, e.g.:
            ```
            dataset/
            ├── case1/
            │   ├── out.e
            │   ├── out.e-s002
            │   └── out.e-s003
            └── case2/
                └── results.e
            ```
            """)
            st.stop()
        
        selected_subdir = st.selectbox("Choose Directory", subdirs, key="subdir_select")
        selected_dir = os.path.join(dataset_dir, selected_subdir)
        
        exodus_files = find_exodus_files(selected_dir, recursive=False)
        
        if not exodus_files:
            st.warning(f"No Exodus files found in '{selected_subdir}'")
            st.stop()
        else:
            st.success(f"Found {len(exodus_files)} file(s)")
        
        # Load and merge mesh if directory changed or not loaded
        if exodus_files and (st.session_state.selected_dir != selected_dir or st.session_state.mesh_data is None):
            st.session_state.selected_dir = selected_dir
            st.session_state.mesh_data = None
            for key in ['mesh_stats', 'points', 'faces', 'face_cell_map', 'current_time_step']:
                st.session_state[key] = None
            
            meshes_data = []
            with st.spinner(f"Loading {len(exodus_files)} file(s) from {selected_subdir}..."):
                for file_path in sorted(exodus_files):
                    mesh_data = load_exodus_data(file_path)
                    if mesh_data:
                        meshes_data.append(mesh_data)
            
            if meshes_data:
                if len(meshes_data) == 1:
                    merged_data = meshes_data[0]
                else:
                    merged_data = merge_meshes(meshes_data)
                
                if merged_data:
                    st.session_state.mesh_data = merged_data
                    
                    # Extract surface geometry
                    mesh = merged_data.get('mesh')
                    if mesh:
                        points, faces, face_cell_map = extract_mesh_surfaces(mesh)
                        st.session_state.points = points
                        st.session_state.faces = faces
                        st.session_state.face_cell_map = face_cell_map
                    
                    # Analyze mesh
                    st.session_state.mesh_stats = analyze_mesh(merged_data, time_step=0)
                    st.session_state.current_time_step = 0
                    
                    st.rerun()
        
        # Time slider
        st.divider()
        st.header("⏱️ Time Controls")
        
        mesh_data = st.session_state.mesh_data
        n_times = 1
        time_values = None
        
        if mesh_data:
            n_times = mesh_data.get('n_times', 1)
            time_values = mesh_data.get('time_values')
        
        if n_times > 1:
            time_step = st.slider(
                "Timestep",
                0, n_times - 1,
                st.session_state.get('current_time_step', n_times - 1),
                key="time_slider"
            )
            st.session_state.current_time_step = time_step
            
            if time_values is not None and len(time_values) >= n_times:
                st.caption(f"Time = {time_values[time_step]:.6g}")
            else:
                st.caption(f"Time Step {time_step + 1} of {n_times}")
            
            # Animation controls
            col_anim1, col_anim2 = st.columns(2)
            with col_anim1:
                if st.button("⏮️ First", key="btn_first"):
                    st.session_state.current_time_step = 0
                    st.rerun()
            with col_anim2:
                if st.button("⏭️ Last", key="btn_last"):
                    st.session_state.current_time_step = n_times - 1
                    st.rerun()
            
            # Auto-play (experimental)
            if st.checkbox("🔄 Auto-play", key="autoplay"):
                sleep_time = st.slider("Speed (seconds/frame)", 0.1, 2.0, 0.5, key="speed")
                import time
                time.sleep(sleep_time)
                st.session_state.current_time_step = (st.session_state.current_time_step + 1) % n_times
                st.rerun()
        else:
            time_step = 0
            st.info("Static mesh (no time steps detected)")
    
    # Main visualization area
    st.divider()
    st.header("2. Visualization Controls")
    
    col_vis1, col_vis2, col_vis3 = st.columns(3)
    with col_vis1:
        color_map = st.selectbox(
            "Color Scale",
            ["Viridis", "Plasma", "Inferno", "Magma", "Cividis",
             "Jet", "Rainbow", "Portland", "Turbo", "Spectral"],
            key="colormap"
        )
    with col_vis2:
        opacity = st.slider("Opacity", 0.1, 1.0, 0.9, 0.05, key="opacity")
        show_edges = st.checkbox("Show Edges", value=False, key="show_edges")
    with col_vis3:
        show_scalar_bar = st.checkbox("Show Color Bar", value=True, key="show_scalar_bar")
        camera_preset = st.selectbox(
            "Camera View",
            ["isometric", "top", "front", "side", "corner"],
            key="camera_preset"
        )
    
    st.divider()
    
    # Info section
    st.header("📊 Mesh Information")
    
    if mesh_data and st.session_state.mesh_stats:
        stats = st.session_state.mesh_stats
        points = st.session_state.points
        faces = st.session_state.faces
        face_cell_map = st.session_state.face_cell_map
        time_step = st.session_state.current_time_step
        
        # Update stats for current time step
        stats = analyze_mesh(mesh_data, time_step=time_step)
        
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            st.markdown(f"""
            <div class="metric-card">
                <div class="metric-value">{stats.get('n_points', 0):,}</div>
                <div class="metric-label">Points</div>
            </div>
            """, unsafe_allow_html=True)
        with col2:
            st.markdown(f"""
            <div class="metric-card">
                <div class="metric-value">{stats.get('n_cells', 0):,}</div>
                <div class="metric-label">Cells</div>
            </div>
            """, unsafe_allow_html=True)
        with col3:
            cell_types = stats.get('cell_types', {})
            st.markdown(f"""
            <div class="metric-card">
                <div class="metric-value">{len(cell_types)}</div>
                <div class="metric-label">Cell Types</div>
            </div>
            """, unsafe_allow_html=True)
        with col4:
            point_vars = stats.get('point_vars', [])
            cell_vars = stats.get('cell_vars', [])
            st.markdown(f"""
            <div class="metric-card">
                <div class="metric-value">{len(point_vars) + len(cell_vars)}</div>
                <div class="metric-label">Variables</div>
            </div>
            """, unsafe_allow_html=True)
        
        # Variable selection
        col_var1, col_var2 = st.columns([3, 1])
        with col_var1:
            all_bases = stats.get('point_vars', []) + stats.get('cell_vars', [])
            if not all_bases:
                st.info("No variables found. Visualizing geometry only.")
                variable_base = None
            else:
                variable_base = st.selectbox(
                    "Select Variable",
                    all_bases,
                    key="var_select",
                    index=0,
                    help="Choose a field to visualize"
                )
        with col_var2:
            if variable_base and variable_base in stats.get('field_info', {}):
                info = stats['field_info'][variable_base]
                range_val = info.get('range')
                if range_val:
                    st.metric("Range", f"{range_val[0]:.3g} to {range_val[1]:.3g}")
        
        # Extract values for current time step
        values = None
        if variable_base and faces is not None and len(faces) > 0:
            values = get_variable_values(
                mesh_data, variable_base, faces, face_cell_map,
                time_step=time_step
            )
        
        # Create visualization
        if points is not None and faces is not None and len(points) > 0 and len(faces) > 0:
            time_label = ""
            if time_values is not None and len(time_values) > time_step:
                time_label = f" (t={time_values[time_step]:.6g})"
            else:
                time_label = f" (Step {time_step + 1}/{n_times})"
            
            fig = create_plotly_mesh(
                points, faces, values,
                color_map=color_map,
                opacity=opacity,
                show_edges=show_edges,
                title=f"{variable_base or 'Geometry'}{time_label}",
                show_scalar_bar=show_scalar_bar,
                camera_preset=camera_preset
            )
            
            st.divider()
            st.subheader("🎨 3D Visualization")
            st.plotly_chart(fig, use_container_width=True, key="plotly_viz")
            
            # Variable distribution histogram
            if values is not None and len(values) > 0:
                with st.expander("📈 Variable Distribution", expanded=False):
                    hist_fig = create_variable_histogram(values, variable_base)
                    if hist_fig:
                        st.plotly_chart(hist_fig, use_container_width=True)
            
            # Time series plot
            if n_times > 1 and variable_base:
                with st.expander("📉 Time Evolution", expanded=False):
                    ts_fig = create_time_series_plot(mesh_data, variable_base, time_step)
                    if ts_fig:
                        st.plotly_chart(ts_fig, use_container_width=True)
        else:
            st.warning("Could not extract mesh surfaces")
            st.markdown("""
            **Try:** Download and open in ParaView for full mesh support.
            """)
        
        # Export section
        st.divider()
        st.subheader("📤 Export for ParaView")
        
        with st.expander("Mesh Details", expanded=False):
            st.write(f"**Directory:** `{selected_subdir}`")
            st.write(f"**Files:** {len(exodus_files)}")
            st.write(f"**Points:** {stats.get('n_points', 0):,}")
            st.write(f"**Cells:** {stats.get('n_cells', 0):,}")
            st.write(f"**Timesteps:** {n_times}")
            if time_values is not None:
                st.write(f"**Time Range:** {time_values[0]:.6g} to {time_values[-1]:.6g}")
            if stats.get('cell_types'):
                st.write("**Cell Types:**")
                for ctype, count in stats['cell_types'].items():
                    st.write(f" - `{ctype}`: {count:,}")
            if stats.get('point_vars'):
                st.write("**Point Variables:**")
                for base in stats['point_vars']:
                    info = stats.get('field_info', {}).get(base, {})
                    st.write(f" - `{base}` {info.get('shape', '')} {info.get('dtype', '')}")
            if stats.get('cell_vars'):
                st.write("**Cell Variables:**")
                for base in stats['cell_vars']:
                    info = stats.get('field_info', {}).get(base, {})
                    st.write(f" - `{base}` {info.get('shape', '')} {info.get('dtype', '')}")
        
        st.markdown("### Available Formats")
        available_formats = {k: v for k, v in SUPPORTED_EXPORT_FORMATS.items()
                           if k in get_meshio_write_formats()}
        
        if not available_formats:
            st.warning("No export formats available. Check meshio installation.")
        else:
            cols = st.columns(min(len(available_formats), 6))
            for idx, (fmt_key, fmt_info) in enumerate(available_formats.items()):
                with cols[idx % len(cols)]:
                    export_filename = f"mesh_output_t{time_step}{fmt_info['ext']}"
                    export_path = os.path.join(st.session_state.cache_dir, export_filename)
                    success, message, file_size = convert_mesh_format(
                        mesh_data, export_path, fmt_key, time_step=time_step
                    )
                    if success and os.path.exists(export_path):
                        with open(export_path, 'rb') as f:
                            file_bytes = f.read()
                        st.download_button(
                            label=f"{fmt_info['name']}",
                            data=file_bytes,
                            file_name=export_filename,
                            mime=fmt_info['mime'],
                            key=f"download_{fmt_key}",
                            help=f"{fmt_info['desc']}\nSize: {format_file_size(file_size)}",
                            type="primary" if fmt_key == 'vtu' else "secondary"
                        )
                    else:
                        st.button(
                            label=f"Unavailable: {fmt_info['name']}",
                            disabled=True,
                            key=f"download_{fmt_key}_disabled",
                            help=f"Unavailable: {message}"
                        )
                    st.caption(fmt_info['desc'].split('(')[0].strip())
        
        with st.expander("Format Comparison Guide", expanded=False):
            st.markdown("""
            | Format | Best For | ParaView | Variables | Size |
            |--------|----------|----------|-----------|------|
            | **VTU** | Full 3D analysis | Excellent | All | Medium |
            | **VTK** | Legacy compatibility | Good | All | Large |
            | **PLY** | Surface visualization | Limited | Point only | Small |
            | **STL** | 3D printing/CAD | Geometry only | None | Small |
            | **XDMF** | Large/parallel data | Excellent | All | Small |
            | **Exodus** | MOOSE re-import | Native | All | Medium |
            """)
        
        st.info("""
        **Recommendation:**
        - Use **VTU** for most ParaView workflows
        - Use **PLY** for quick surface previews
        - Use **CSV** (below) for data analysis in Excel/Python
        """)
        
        # CSV Export
        if variable_base:
            st.markdown("### 📊 Export Variable Data (CSV)")
            csv_filename = f"{variable_base}_t{time_step}_data.csv"
            csv_path = os.path.join(st.session_state.cache_dir, csv_filename)
            csv_success, csv_msg = export_variable_csv(
                mesh_data, variable_base, csv_path, time_step=time_step
            )
            if csv_success and os.path.exists(csv_path):
                with open(csv_path, 'rb') as f:
                    csv_bytes = f.read()
                col_csv1, col_csv2 = st.columns([3, 1])
                with col_csv1:
                    st.download_button(
                        label=f"Download {csv_filename}",
                        data=csv_bytes,
                        file_name=csv_filename,
                        mime="text/csv",
                        key="download_csv",
                        help="Variable values with point coordinates"
                    )
                with col_csv2:
                    try:
                        row_count = pd.read_csv(csv_path).shape[0]
                        st.metric("Rows", f"{row_count:,}")
                    except Exception:
                        st.metric("Rows", "Unknown")
            else:
                st.button("CSV Export Unavailable", disabled=True, help=csv_msg)
        
        st.info("""
        **ParaView Import Guide:**
        1. Download `.vtu` file (recommended for full 3D mesh)
        2. Open ParaView → File → Open → Select file
        3. Click "Apply" in Properties panel
        4. Use "Color By" to select variables
        5. Click "Rescale to Data Range" for proper colors
        """)
    
    else:
        if mesh_data is None:
            st.error("Failed to load mesh. Check file format and dependencies.")
        else:
            st.warning("No variable data found. The mesh might be empty or have no data.")
    
    # Footer
    st.divider()
    st.markdown("""
    <div style="text-align: center; color: gray; padding: 1rem;">
    <small>
    MOOSE Exodus Viewer v3.0 |
    Built with Streamlit + Plotly + Meshio + NetCDF4 |
    <a href="https://mooseframework.inl.gov" target="_blank">MOOSE Framework</a>
    </small>
    </div>
    """, unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# Entry Point
# -----------------------------------------------------------------------------
if __name__ == "__main__":
    main()
