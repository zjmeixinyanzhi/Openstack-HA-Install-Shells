       ssh controller03 /bin/bash << EOF 
            echo 123456 | passwd --stdin hacluster 
EOF
