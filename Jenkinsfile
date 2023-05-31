node {
    def application = 'springbootapp'
    def dockerhubaccountid = 'aliabolhassani'

    stage('Clone repository') {
        checkout scm
    }

    stage('Stop Docker containers') {
        sh '(docker container rm -f $(docker ps -a -q)) || true'
    }

    stage('Run unit tets') {
        sh('./mvnw test')
    }

    stage('Build the Artifact') {
        sh('./mvnw clean package')
    }

    stage('Build image') {
        app = docker.build("${dockerhubaccountid}/${application}:${BUILD_NUMBER}")
    }

    stage('Push image') {
        withDockerRegistry([ credentialsId: 'dockerHub', url: '' ]) {
            app.push()
            app.push('latest')
        }
    }

    stage('Deploy') {
        sh("docker run -d -p 81:8080 -v /var/log/:/var/log/ ${dockerhubaccountid}/${application}:${BUILD_NUMBER}")
    }

    stage('Remove old images') {
        // remove docker pld images
        sh("docker rmi ${dockerhubaccountid}/${application}:latest -f")
    }
}
