#!/bin/bash --login
#SBATCH --job-name=bead_monotop_job
#SBATCH --output=monotop_job_%j.log
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=24:00:00
#SBATCH --partition=serial

# Printing job information
echo "Job started at: $(date)"
echo "Running on node: $(hostname)"
echo "Current working directory: $(pwd)"

module load poetry

# Setting up workspace and project names
WORKSPACE_NAME="monotop_detection"
PROJECT_NAME="monotope_200_A"

# Creating a new project
echo "Creating new project..."
poetry run bead -m new_project -p ${WORKSPACE_NAME} ${PROJECT_NAME}

echo "Copying input data to workspace..."
cp ${HOME}/BEAD/bead/workspaces/dq/data/csv/* ${HOME}/BEAD/bead/workspaces/${WORKSPACE_NAME}/data/csv/

# Updating the configuration file
CONFIG_FILE="${HOME}/BEAD/bead/workspaces/${WORKSPACE_NAME}/${PROJECT_NAME}/config/${PROJECT_NAME}_config.py"
echo "Updating configuration file: ${CONFIG_FILE}"

sed -i "s/c.model_name\s*=\s*\"ConvVAE\"/c.model_name = \"Planar_ConvVAE\"/" ${CONFIG_FILE}
sed -i "s/c.epochs\s*=\s*[0-9]*/c.epochs = 500/" ${CONFIG_FILE}
sed -i "s/c.intermittent_model_saving\s*=\s*[a-zA-Z]*/c.intermittent_model_saving = True/" ${CONFIG_FILE}
sed -i "s/c.intermittent_saving_patience\s*=\s*[0-9]*/c.intermittent_saving_patience = 100/" ${CONFIG_FILE}

echo "Updated configuration values:"
grep "c.model_name" ${CONFIG_FILE}
grep "c.epochs" ${CONFIG_FILE}
grep "c.intermittent_model_saving" ${CONFIG_FILE}
grep "c.intermittent_saving_patience" ${CONFIG_FILE}

# Running the complete pipeline
echo "Starting BEAD pipeline..."
poetry run bead -m convert_csv -p ${WORKSPACE_NAME} ${PROJECT_NAME}
poetry run bead -m prepare_inputs -p ${WORKSPACE_NAME} ${PROJECT_NAME}
poetry run bead -m train -p ${WORKSPACE_NAME} ${PROJECT_NAME}
poetry run bead -m detect -p ${WORKSPACE_NAME} ${PROJECT_NAME}
poetry run bead -m plot -p ${WORKSPACE_NAME} ${PROJECT_NAME}

echo "Job completed at: $(date)"

# Archiving the results
RESULTS_DIR="${HOME}/BEAD/bead/workspaces/${WORKSPACE_NAME}/${PROJECT_NAME}/output"
ARCHIVE_NAME="${PROJECT_NAME}_$(date +%Y%m%d_%H%M%S).tar.gz"

echo "Archiving results to ${ARCHIVE_NAME}..."
tar -czf ${HOME}/BEAD/bead/workspaces/${WORKSPACE_NAME}/${ARCHIVE_NAME} -C ${RESULTS_DIR} .

echo "Results archived to: ${HOME}/BEAD/bead/workspaces/${WORKSPACE_NAME}/${ARCHIVE_NAME}"
echo "All steps completed successfully!"
