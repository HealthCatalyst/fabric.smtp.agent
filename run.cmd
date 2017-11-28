docker stop fabric.smtp.agent
docker rm fabric.smtp.agent

docker build -t healthcatalyst/fabric.smtp.agent . 

docker run -p 25:25 --rm --name fabric.smtp.agent -t healthcatalyst/fabric.smtp.agent
