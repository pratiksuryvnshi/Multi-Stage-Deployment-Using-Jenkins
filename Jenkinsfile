pipeline {
    agent { label 'K8s-Node' }

    environment {
        PROJECT_ID = 'poetic-bison-439113-i4'
        IMAGE_NAME = "gcr.io/poetic-bison-439113-i4/hello-cloudbuild"
        COMMIT_SHA = "v1"  // Default to 'latest' if GIT_COMMIT is not available
        CLUSTER_NAME = 'hello-world'
        ZONE = 'us-central1-a'
        TF_DIR = '/home/dev_pratiksuryavanshi/Terraform/Project-1' // Path to your Terraform configuration
    }

    stages {
        stage('Test') {
            steps {
                script {
                    sh 'docker pull python:3.7-slim'
                    sh 'docker run --rm -v /home/dev_pratiksuryavanshi:/workspace -w /workspace python:3.7-slim pip install --user flask'
                    sh '''
                        docker run --rm -v /home/dev_pratiksuryavanshi:/workspace -w /workspace python:3.7-slim /bin/bash -c "
                        pip install flask &&
                        python test_app.py -v
                          "
                     '''
                }
            }
        }

        stage('Terraform: Deploy K8s') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'gcp-jenkins-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'

                        // Initialize Terraform
                        dir(TF_DIR) {
                            sh 'terraform init'
                            
                            // Plan Terraform changes
                            sh "terraform plan"

                            // Apply Terraform plan
                            sh 'terraform apply -auto-approve'
                        }
                    }
                }
            }
        }

        stage('Build Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:v1 /home/dev_pratiksuryavanshi"
                }
            }
        }

        stage('Push Image') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'gcp-jenkins-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'
                        sh 'gcloud auth configure-docker gcr.io --quiet'
                        sh "docker push ${IMAGE_NAME}:v1"
                    }
                }
            }
        }

        stage('Deploy to GKE') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'gcp-jenkins-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'
                        sh "gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${REGION} --project ${PROJECT_ID}"

                        // Update the Kubernetes manifest with the correct image tag
                        
                        sh "kubectl apply -f /home/dev_pratiksuryavanshi/kubernetes.yaml --validate=false"
                    }
                }
            }
        }

        stage('Check Pod Status') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'gcp-jenkins-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'
                        sh "kubectl get pods"
                    }
                }
            }
        }
    }
}
