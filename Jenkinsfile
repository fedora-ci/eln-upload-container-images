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
        stage('Trigger build') {
            steps {
                script {
                    sh("""
eln_build_name=$(koji -q latest-build --type=image eln-updates-candidate Fedora-Container-Base | awk '{print $1}')
if [[ -n ${eln_build_name} ]]; then
    # Download the image
    work_dir=$(mktemp -d)
    pushd ${work_dir} &> /dev/null
    koji download-build --type=image  ${eln_build_name}

    # Import the image
    xz -d ${eln_build_name}.x86_64.tar.xz
    skopeo copy docker-archive:${eln_build_name}.x86_64.tar docker://quay.io/fedoraci/fedora:eln-x86_64
    popd &> /dev/null

    printf "Removing temporary directory\n"
    rm -rf $work_dir
fi
                    """
                }
            }
        }
    }
}
