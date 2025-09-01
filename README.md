1. In Dockerfile enable the blocks below AMD64 or ARM64 depending on what you use Aarch64 or x86_64
2. For MacOS enable netty-resolver-dns-native-macos in the pom.xml and use the correct classifier 
3. Run `mvn verify`
4. run command 
```shell
docker build -t testimg .
```
5. run command 
```shell
docker images
```
to find the image id
6. run command
```shell 
docker run --rm testimg
``` 
to run the actual image