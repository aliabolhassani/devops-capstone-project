node {
    def application = 'springbootapp'
    def dockerhubaccountid = 'aliabolhassani'

    stage('Clone Repository') {
        checkout scm
    }

    stage('Stop Docker Containers') {
        sh('(docker container rm -f $(docker ps -a -q)) || true')
    }

    stage('Run Unit Tets') {
        sh('./mvnw test')
    }

    stage('Build the Artifact') {
        sh('./mvnw clean package')
    }

    stage('Build Image') {
        app = docker.build("${dockerhubaccountid}/${application}:${BUILD_NUMBER}")
    }

    stage('Push Image') {
        withDockerRegistry([ credentialsId: 'dockerHub', url: '' ]) {
            app.push()
            app.push('latest')
        }
    }

    stage('Deploy') {
        sh("docker run -d -p 80:8080 -v /var/log/:/var/log/ ${dockerhubaccountid}/${application}:${BUILD_NUMBER}")
    }

    stage('Remove Old Images') {
        sh("docker rmi ${dockerhubaccountid}/${application}:latest -f")
    }
}
