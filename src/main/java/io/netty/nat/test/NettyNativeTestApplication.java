package io.netty.nat.test;

import io.netty.handler.ssl.SslContext;
import io.netty.handler.ssl.SslContextBuilder;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.ExitCodeGenerator;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.MediaType;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;

@SpringBootApplication
@Slf4j
public class NettyNativeTestApplication implements CommandLineRunner {

    public static void main(String[] args) {
        System.exit(
            SpringApplication.exit(
                SpringApplication.run(NettyNativeTestApplication.class, args)
            )
        );
    }

    @Override
    public void run(String... args) throws Exception {
        try {
            SslContext sslContext = SslContextBuilder.forClient()
                .protocols("TLSv1.2", "TLSv1.3")
                .build();

            HttpClient httpClient = HttpClient.create()
                .secure(ssl -> ssl.sslContext(sslContext));

            WebClient webClient = WebClient
                .builder()
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .baseUrl("https://www.google.com")
                .build();

            String result = webClient
                .get()
                .uri("/")
                .accept(MediaType.TEXT_PLAIN)
                .retrieve()
                .bodyToMono(String.class)
                .block();
            log.info("result: {}", result);
        } catch (Exception e) {
            throw new ExitCodeGeneratorException(e);
        }
    }

    private static class ExitCodeGeneratorException extends RuntimeException implements ExitCodeGenerator {

        public ExitCodeGeneratorException(Throwable e) {
            super(e);
        }

        @Override
        public int getExitCode() {
            return 1;
        }
    }

}
