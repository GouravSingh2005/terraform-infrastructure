pipeline {
    agent any

    environment {
        // Terraform settings
        TF_IN_AUTOMATION = "true"
        TF_INPUT = "false"
        TF_CLI_ARGS = "-no-color"

        // Backend configuration
        TF_STATE_BUCKET = credentials('TF_STATE_BUCKET')
        TF_STATE_KEY = credentials('TF_STATE_KEY')
        TF_STATE_REGION = credentials('TF_STATE_REGION')
        TF_LOCK_TABLE = credentials('TF_LOCK_TABLE')

        // AWS Region
        AWS_REGION = credentials('AWS_REGION')
        AWS_DEFAULT_REGION = "${AWS_REGION}"

        // Terraform variables from Jenkins credentials
        TF_VAR_region = credentials('TF_VAR_region')
        TF_VAR_environment = credentials('TF_VAR_environment')
        TF_VAR_project_name = credentials('TF_VAR_project_name')
        TF_VAR_owner = credentials('TF_VAR_owner')
        TF_VAR_vpc_cidr = credentials('TF_VAR_vpc_cidr')
        TF_VAR_public_subnet_cidrs = credentials('TF_VAR_public_subnet_cidrs')
        TF_VAR_private_app_subnet_cidrs = credentials('TF_VAR_private_app_subnet_cidrs')
        TF_VAR_private_db_subnet_cidrs = credentials('TF_VAR_private_db_subnet_cidrs')
        TF_VAR_instance_type = credentials('TF_VAR_instance_type')
        TF_VAR_desired_capacity = credentials('TF_VAR_desired_capacity')
        TF_VAR_min_capacity = credentials('TF_VAR_min_capacity')
        TF_VAR_max_capacity = credentials('TF_VAR_max_capacity')
        TF_VAR_ssh_allowed_cidr = credentials('TF_VAR_ssh_allowed_cidr')
        TF_VAR_domain_name = credentials('TF_VAR_domain_name')
        TF_VAR_subdomain = credentials('TF_VAR_subdomain')
        TF_VAR_acm_certificate_arn = credentials('TF_VAR_acm_certificate_arn')
        TF_VAR_key_name = credentials('TF_VAR_key_name')
        TF_VAR_app_port = credentials('TF_VAR_app_port')
        TF_VAR_root_volume_size = credentials('TF_VAR_root_volume_size')
        TF_VAR_enable_deletion_protection = credentials('TF_VAR_enable_deletion_protection')
        TF_VAR_enable_alb_access_logs = credentials('TF_VAR_enable_alb_access_logs')
        TF_VAR_alb_access_logs_bucket_name = credentials('TF_VAR_alb_access_logs_bucket_name')
        TF_VAR_tf_state_bucket_name = credentials('TF_VAR_tf_state_bucket_name')
        TF_VAR_tf_lock_table_name = credentials('TF_VAR_tf_lock_table_name')
        TF_VAR_github_owner = credentials('TF_VAR_github_owner')
        TF_VAR_github_repo = credentials('TF_VAR_github_repo')
        TF_VAR_github_branch = credentials('TF_VAR_github_branch')
        TF_VAR_monitoring_alarm_actions = credentials('TF_VAR_monitoring_alarm_actions')
    }

    options {
        timestamps()
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '10'))
    }

    triggers {
        // Poll SCM every 15 minutes for changes
        pollSCM('H/15 * * * *')
        
        // Or use GitHub webhook (requires GitHub plugin)
        // githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "========== Checking out source code =========="
                    checkout scm
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    echo "========== Installing Terraform and dependencies =========="
                    sh '''
                        # Install required tools
                        apt-get update || yum update
                        apt-get install -y unzip curl || yum install -y unzip curl

                        # Install Terraform
                        TF_VERSION="1.8.5"
                        curl -fsSLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
                        unzip -o /tmp/terraform.zip -d /usr/local/bin
                        terraform version
                    '''
                }
            }
        }

        stage('Build - Format & Init') {
            steps {
                script {
                    echo "========== Running terraform fmt and init =========="
                    sh '''
                        # Format check
                        terraform fmt -check -recursive

                        # Initialize backend
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
        }

        stage('Test - Validate & Plan') {
            steps {
                script {
                    echo "========== Running terraform validate and plan =========="
                    sh '''
                        # Validate
                        terraform validate

                        # Plan
                        terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Approval') {
            steps {
                script {
                    echo "========== Waiting for approval to deploy =========="
                    input(
                        id: 'terraform-apply',
                        message: 'Do you want to apply the Terraform changes?',
                        ok: 'Apply',
                        submitter: 'terraform-admins'
                    )
                }
            }
        }

        stage('Deploy - Apply') {
            steps {
                script {
                    echo "========== Running terraform apply =========="
                    sh '''
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }
    }

    post {
        always {
            script {
                echo "========== Pipeline Execution Complete =========="
                
                // Clean up
                sh 'rm -f tfplan'
                
                // Archive logs and state information
                archiveArtifacts(
                    artifacts: '**/*.json, **/*.txt, .terraform/**',
                    allowEmptyArchive: true
                )
            }
        }

        success {
            echo "✓ Pipeline executed successfully"
            // Add notification: emailext, slack, etc.
        }

        failure {
            echo "✗ Pipeline failed"
            // Add notification: emailext, slack, etc.
        }

        unstable {
            echo "⚠ Pipeline is unstable"
            // Add notification: emailext, slack, etc.
        }
    }
}
