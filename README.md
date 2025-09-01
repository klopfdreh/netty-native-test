1. Run `mvn verify`
2. run command `docker build -t testimg .`
3. run command `docker images` to find the image id
4. run command `docker run --rm testimg` to run the actual image