// src/main/java/com/example/demo/controller/HealthController.java
package com.example.demo.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    @GetMapping("/")
    public String home() {
        return "Backend is running!";
    }

    @GetMapping("/api/health")
    public String health() {
        return "OK";
    }

    // 🆕 새로 추가: 상세 헬스체크
    @GetMapping("/api/health/detailed")
    public HealthStatus detailedHealth() {
        return new HealthStatus("UP", System.currentTimeMillis());
    }

    // 🆕 새로 추가
    @GetMapping("/api/version")
    public String version() {
        return "v2.0.4";
    }

    // 🆕 내부 클래스 추가
    static class HealthStatus {
        private String status;
        private long timestamp;

        public HealthStatus(String status, long timestamp) {
            this.status = status;
            this.timestamp = timestamp;
        }

        public String getStatus() {
            return status;
        }

        public void setStatus() {
            status = "default22";
        }

        public long getTimestamp() {
            return timestamp;
        }


    }
}