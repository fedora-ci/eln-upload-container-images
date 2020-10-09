#!groovy

def podYAML = '''
spec:
  containers:
  - name: koji
    image: quay.io/jkaluza/koji-skopeo:latest
    tty: true
'''

properties(
    [
        parameters(
            [
                string(description: 'CI Message', defaultValue: '', name: 'CI_MESSAGE'),
            ]
        ),
        pipelineTriggers(
            [
                [
                    $class: 'CIBuildTrigger',
                    noSquash: true,
                    providerData: [
                        $class: 'RabbitMQSubscriberProviderData',
                        name: 'RabbitMQ',
                        overrides: [
                            topic: 'org.fedoraproject.prod.buildsys.tag',
                            queue: 'osci-pipelines-queue-13'
                        ],

                        checks: [
                            [
                                expectedValue: '^eln-updates-candidate$',
                                field: '$.tag'
                            ],
                            [
                                expectedValue: '^Fedora-Container-Base$',
                                field: '$.name'
                            ]
                        ]
                    ]
                ]
            ]
        )
    ]
)

def msg

pipeline {

    agent {
        kubernetes {
            yaml podYAML
            defaultContainer 'koji'
        }
    }

    stages {
        stage('Upload image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'fedoraci-eln-publisher', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh "./sync-latest-container-base-image.sh"
                    }
                }
            }
        }
    }
}
