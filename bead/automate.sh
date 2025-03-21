#!/bin/bash

# Printing job information
echo "Job started at: $(date)"
echo "Running on: $(hostname)"
echo "Current working directory: $(pwd)"

# Setting up workspace name
WORKSPACE_NAME="monotop_detection"

# Defining arrays for model types and learning rates
MODEL_TYPES=("AE" "AE_Dropout_BN" "ConvAE" "ConvVAE" "Planar_ConvVAE" "OrthogonalSylvester_ConvVAE" "HouseholderSylvester_ConvVAE"
              "TriangularSylvester_ConvVAE" "IAF_ConvVAE" "ConvFlow_ConvVAE" "NSFAR_ConvVAE" "TransformerAE")
LEARNING_RATES=(0.001 0.0001)
REG_PARAMS=(0.01 0.001)

# Looping through each model type and learning rate combination
for MODEL in "${MODEL_TYPES[@]}"; do
    for LR in "${LEARNING_RATES[@]}"; do
        for REG in "${REG_PARAMS[@]}"; do
            LR_FORMATTED=$(echo ${LR} | sed 's/\./p/g')
            REG_FORMATTED=$(echo ${REG} | sed 's/\./p/g')
            PROJECT_NAME="${MODEL}_${LOSS}_lr${LR_FORMATTED}_reg${REG_FORMATTED}_500ep"
            
            echo "==============================================================="
            echo "Starting configuration: Model=${MODEL}, Learning Rate=${LR}, Regularization_param=${REG}"
            echo "Project name: ${PROJECT_NAME}"
            echo "==============================================================="
            
            # Creating a new project
            echo "Creating new project..."
            poetry run bead -m new_project -p ${WORKSPACE_NAME} ${PROJECT_NAME}
            
            # Copying the input data to the workspace (only if it doesn't exist)
            if [ -z "$(ls -A ./workspaces/${WORKSPACE_NAME}/data/csv)" ]; then
                echo "Copying input data to workspace..."
                cp ./workspaces/dq/data/csv/* ./workspaces/${WORKSPACE_NAME}/data/csv/
                poetry run bead -m chain -p ${WORKSPACE_NAME} ${PROJECT_NAME} -o convertcsv_prepareinputs
            else
                echo "Input data already exists in workspace, skipping copy..."
            fi
            
            # Checking for GPU (only in the first iteration)
            if [ "$MODEL" == "${MODEL_TYPES[0]}" ] && [ "$LR" == "${LEARNING_RATES[0]}" ]; then
                if command -v nvidia-smi &> /dev/null; then
                    echo "GPU found. Details:"
                    nvidia-smi
                else
                    echo "WARNING: No NVIDIA GPU detected, or nvidia-smi not found. The script will continue but may run on CPU only."
                fi
            fi
            
            # Updating the configuration file
            CONFIG_FILE="./workspaces/${WORKSPACE_NAME}/${PROJECT_NAME}/config/${PROJECT_NAME}_config.py"
            echo "Updating configuration file: ${CONFIG_FILE}"

            sed -i "s/c.model_name\s*=\s*\"[^\"]*\"/c.model_name = \"${MODEL}\"/" ${CONFIG_FILE}
            sed -i "s/c.lr\s*=\s*[0-9.]*/c.lr = ${LR}/" ${CONFIG_FILE}
            sed -i "s/c.epochs\s*=\s*[0-9]*/c.epochs = 500/" ${CONFIG_FILE}
            sed -i "s/c.reg_param\s*=\s*[0-9.]*/c.reg_param = ${REG}/" ${CONFIG_FILE}
            sed -i "s/c.early_stopping\s*=\s*[a-zA-Z]*/c.early_stopping = False/" ${CONFIG_FILE}
            sed -i "s/c.intermittent_model_saving\s*=\s*[a-zA-Z]*/c.intermittent_model_saving = True/" ${CONFIG_FILE}
            sed -i "s/c.intermittent_saving_patience\s*=\s*[0-9]*/c.intermittent_saving_patience = 100/" ${CONFIG_FILE}
            
            echo "Updated configuration values:"
            grep "c.model_name" ${CONFIG_FILE}
            grep "c.learning_rate" ${CONFIG_FILE}
            grep "c.epochs" ${CONFIG_FILE}
            grep "c.reg_param" ${CONFIG_FILE}
            grep "c.early_stopping" ${CONFIG_FILE}
            grep "c.intermittent_model_saving" ${CONFIG_FILE}
            grep "c.intermittent_saving_patience" ${CONFIG_FILE}
            
            # Running the complete pipeline
            echo "Starting BEAD pipeline for ${PROJECT_NAME}..."
            poetry run bead -m chain -p ${WORKSPACE_NAME} ${PROJECT_NAME} -o train_detect_plot 
            
            # Archiving the results
            RESULTS_DIR="./workspaces/${WORKSPACE_NAME}/${PROJECT_NAME}/output"
            ARCHIVE_NAME="${MODEL}_lr${LR}_500ep_results_$(date +%Y%m%d_%H%M%S).tar.gz"
            
            echo "Archiving results to ${ARCHIVE_NAME}..."
            tar -czf ./workspaces/${WORKSPACE_NAME}/${ARCHIVE_NAME} -C ${RESULTS_DIR} .
            
            echo "Results archived to: ./workspaces/${WORKSPACE_NAME}/${ARCHIVE_NAME}"
            echo "Configuration completed successfully!"
        done
    done
done

# Printing job completion information
echo "All configurations completed at: $(date)"
echo "Total configurations processed: $((${#MODEL_TYPES[@]} * ${#LEARNING_RATES[@]} * ${#REG_PARAMS[@]}))"