pipeline {
    agent any

    environment {

        // Terraform settings
        TF_IN_AUTOMATION = "true"
        TF_INPUT = "false"
        TF_CLI_ARGS = "-no-color"

        // AWS Region
        AWS_REGION = "ap-south-1"
        AWS_DEFAULT_REGION = "ap-south-1"

        // Backend Configuration
        TF_STATE_BUCKET = "setup-enterprise-3tier-prod-tfstate-tfstate"

        TF_STATE_KEY = "prod/terraform.tfstate"

        TF_STATE_REGION = "ap-south-1"

        TF_LOCK_TABLE = "setup-enterprise-3tier-prod-tfstate-tf-locks"

        // Terraform Variables
        TF_VAR_region = "ap-south-1"

        TF_VAR_environment = "prod"

        TF_VAR_project_name = "enterprise-3tier"

        TF_VAR_owner = "gourav"

        TF_VAR_vpc_cidr = "10.0.0.0/16"

        TF_VAR_public_subnet_cidrs = "[\"10.0.1.0/24\",\"10.0.2.0/24\"]"

        TF_VAR_private_app_subnet_cidrs = "[\"10.0.3.0/24\",\"10.0.4.0/24\"]"

        TF_VAR_private_db_subnet_cidrs = "[\"10.0.5.0/24\",\"10.0.6.0/24\"]"

        TF_VAR_instance_type = "t2.micro"

        TF_VAR_desired_capacity = "1"

        TF_VAR_min_capacity = "1"

        TF_VAR_max_capacity = "2"

        TF_VAR_app_port = "80"

        TF_VAR_root_volume_size = "20"

        TF_VAR_enable_deletion_protection = "false"

        TF_VAR_enable_alb_access_logs = "false"

        TF_VAR_alb_access_logs_bucket_name = "enterprise-3tier-prod-alb-logs"

        TF_VAR_tf_state_bucket_name = "setup-enterprise-3tier-prod-tfstate-tfstate"

        TF_VAR_tf_lock_table_name = "setup-enterprise-3tier-prod-tfstate-tf-locks"

        TF_VAR_github_owner = "GouravSingh2005"

        TF_VAR_github_repo = "terraform-infrastructure"

        TF_VAR_github_branch = "main"

        // ACM Certificate ARN
        TF_VAR_acm_certificate_arn = "arn:aws:acm:ap-south-1:626052500009:certificate/96174bb0-b5d4-4278-a9fb-1cb7457dc95a"
    }

    options {

        timestamps()

        timeout(time: 1, unit: 'HOURS')

        buildDiscarder(
            logRotator(
                numToKeepStr: '30',
                artifactNumToKeepStr: '10'
            )
        )
    }

    triggers {

        // Jenkins checks GitHub every minute
        pollSCM('* * * * *')
    }

    stages {

        stage('Checkout') {

            steps {

                echo "========== Checking out source code =========="

                checkout scm
            }
        }

        stage('Install Terraform') {

            steps {

                echo "========== Installing Terraform =========="

                sh '''
                    if ! command -v terraform > /dev/null 2>&1
                    then
                        sudo apt-get update

                        sudo apt-get install -y unzip curl

                        TF_VERSION="1.8.5"

                        curl -fsSLo /tmp/terraform.zip \
                        https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip

                        unzip -o /tmp/terraform.zip -d /tmp

                        sudo mv /tmp/terraform /usr/local/bin/

                        terraform version
                    else
                        terraform version
                    fi
                '''
            }
        }

        stage('Terraform Init') {

            steps {

                echo "========== Terraform Init =========="

                sh '''
                    terraform init \
                    -input=false \
                    -backend-config="bucket=${TF_STATE_BUCKET}" \
                    -backend-config="key=${TF_STATE_KEY}" \
                    -backend-config="region=${TF_STATE_REGION}" \
                    -backend-config="dynamodb_table=${TF_LOCK_TABLE}" \
                    -backend-config="encrypt=true"
                '''
            }
        }

        stage('Terraform Format') {

            steps {

                echo "========== Terraform Format =========="

                sh '''
                    terraform fmt -check -recursive
                '''
            }
        }

        stage('Terraform Validate') {

            steps {

                echo "========== Terraform Validate =========="

                sh '''
                    terraform validate
                '''
            }
        }

        stage('Terraform Plan') {

            steps {

                echo "========== Terraform Plan =========="

                sh '''
                    terraform plan -out=tfplan
                '''
            }
        }

        stage('Terraform Apply') {

            steps {

                echo "========== Terraform Apply =========="

                sh '''
                    terraform apply -auto-approve tfplan
                '''
            }
        }
    }

    post {

        always {

            echo "========== Pipeline Execution Complete =========="

            archiveArtifacts(
                artifacts: 'tfplan',
                allowEmptyArchive: true
            )

            deleteDir()
        }

        success {

            echo "✓ Pipeline executed successfully"
        }

        failure {

            echo "✗ Pipeline failed"
        }

        unstable {

            echo "⚠ Pipeline is unstable"
        }
    }
}