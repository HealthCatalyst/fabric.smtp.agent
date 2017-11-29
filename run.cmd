docker stop fabric.smtp.agent
docker rm fabric.smtp.agent

docker build -t healthcatalyst/fabric.smtp.agent . 

docker run -p 25:25 --rm --name fabric.smtp.agent -e SMTP_RELAY_USERNAME=apikey -e SMTP_RELAY_PASSWORD=(include here) -e SMTP_RELAY_SERVER=smtp.sendgrid.net -e SMTP_RELAY_PORT=587 -t healthcatalyst/fabric.smtp.agent
