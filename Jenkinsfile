pipeline {
    agent { label 'K8s-Node' }

    environment {
        PROJECT_ID = 'poetic-bison-439113-i4'
        IMAGE_NAME = "gcr.io/$PROJECT_ID/hello-cloudbuild"
        COMMIT_SHA = "v1"  
        CLUSTER_NAME = 'hello-world'
        ZONE = 'us-central1'
        TF_DIR = '$(pwd)/terraform' 
    }

    stages {
        stage('Test') {
            steps {
                script {
                    sh 'docker pull python:3.7-slim'
                    sh 'docker run --rm -v $(pwd):/workspace -w /workspace python:3.7-slim pip install --user flask'
                    sh '''
                        docker run --rm -v $(pwd):/workspace -w /workspace python:3.7-slim /bin/bash -c "
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
                        sh 'gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"'

                        
                        dir(TF_DIR) {
                            sh 'terraform init'                       
                            sh "terraform plan"                        
                            sh 'terraform apply -auto-approve'
                        }
                    }
                }
            }
        }

        stage('Build Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:v1 $(pwd)"
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
                        sh 'gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"'
                        sh "gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${REGION} --project ${PROJECT_ID}"
                                               
                        sh "kubectl apply -f $(pwd)/kubernetes.yaml --validate=false"
                    }
                }
            }
        }

        stage('Check Pod Status') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'gcp-jenkins-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh 'gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"'
                        sh "kubectl get pods"
                        sh "kubectl get services"
                    }
                }
            }
        }
    }
}
