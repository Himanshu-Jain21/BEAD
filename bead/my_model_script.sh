#!/bin/bash

# Printing the job information
echo "Job started at: $(date)"
echo "Running on node: $(hostname)"
echo "Current working directory: $(pwd)"

# Setting up workspace and project names
WORKSPACE_NAME="monotop_detection"
PROJECT_NAME="my_model_epoch2"

# Creating a new project
echo "Creating new project..."
poetry run bead -m new_project -p ${WORKSPACE_NAME} ${PROJECT_NAME}

echo "Copying input data to workspace..."
cp ./workspaces/dq/data/csv/* ./workspaces/${WORKSPACE_NAME}/data/csv/

# Updating the configuration file
CONFIG_FILE="./workspaces/${WORKSPACE_NAME}/${PROJECT_NAME}/config/${PROJECT_NAME}_config.py"
echo "Updating configuration file: ${CONFIG_FILE}"

sed -i "s/c.model_name\s*=\s*\"[^\"]*\"/c.model_name = \"my_model\"/" ${CONFIG_FILE}
sed -i "s/c.epochs\s*=\s*[0-9]*/c.epochs = 2/" ${CONFIG_FILE}
sed -i "s/c.early_stopping\s*=\s*[a-zA-Z]*/c.early_stopping = False/" ${CONFIG_FILE}
sed -i "s/c.intermittent_model_saving\s*=\s*[a-zA-Z]*/c.intermittent_model_saving = True/" ${CONFIG_FILE}
sed -i "s/c.intermittent_saving_patience\s*=\s*[0-9]*/c.intermittent_saving_patience = 100/" ${CONFIG_FILE}

echo "Updated configuration values:"
grep "c.model_name" ${CONFIG_FILE}
grep "c.epochs" ${CONFIG_FILE}
grep "c.early_stopping" ${CONFIG_FILE}
grep "c.intermittent_model_saving" ${CONFIG_FILE}
grep "c.intermittent_saving_patience" ${CONFIG_FILE}

# Running the complete pipeline
echo "Starting BEAD pipeline..."
poetry run bead -m chain -p ${WORKSPACE_NAME} ${PROJECT_NAME} -o convertcsv_prepareinputs_train_detect_plot 

echo "Job completed at: $(date)"

# Archiving the results
RESULTS_DIR="./workspaces/${WORKSPACE_NAME}/${PROJECT_NAME}/output"
ARCHIVE_NAME="my_model_$(date +%Y%m%d_%H%M%S).tar.gz"

echo "Archiving results to ${ARCHIVE_NAME}..."
tar -czf ./workspaces/${WORKSPACE_NAME}/${ARCHIVE_NAME} -C ${RESULTS_DIR} .

echo "Results archived to: ./workspaces/${WORKSPACE_NAME}/${ARCHIVE_NAME}"
echo "All steps completed successfully!"