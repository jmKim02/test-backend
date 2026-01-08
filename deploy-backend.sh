#!/bin/bash

# ===== 설정 =====
SSH_KEY="~/testgcp/gcp-key"
SERVER_USER="jmkim990226"
SERVER_IP="34.50.8.100"
BACKEND_JAR="./build/libs/demo-0.0.1-SNAPSHOT.jar"

# 타임스탬프 생성
TIMESTAMP=$(date +%Y%m%d%H%M%S)

echo "========================================="
echo "백엔드 배포 시작"
echo "========================================="

# ===== 로컬 환경 =====

# 1. 로컬 빌드
echo ""
echo "1. 로컬 빌드 중..."
./gradlew clean build -x test || {
    echo "❌ 빌드 실패!"
    exit 1
}
echo "✅ 빌드 완료"

# 2. JAR 파일 전송
echo ""
echo "2. JAR 파일 전송 중... (backend-$TIMESTAMP.jar)"
scp -i $SSH_KEY $BACKEND_JAR $SERVER_USER@$SERVER_IP:~/backend/release/backend-$TIMESTAMP.jar || {
    echo "❌ 파일 전송 실패!"
    exit 1
}
echo "✅ 파일 전송 완료"

# ===== 서버 환경 =====

# 3. 서버에서 배포 실행
echo ""
echo "3. 서버에서 배포 실행 중..."
ssh -i $SSH_KEY $SERVER_USER@$SERVER_IP << 'EOF'
    echo ""
    echo "  [서버] 배포 프로세스 시작"
    
    # 디렉토리 확인 (이미 있겠지만 혹시 모르니)
    mkdir -p ~/backend/release
    
    # 기존 프로세스 종료
    echo "  → 기존 프로세스 종료 중..."
    pkill -f 'backend.jar' && echo "     기존 프로세스 종료됨" || echo "     기존 프로세스 없음"
    sleep 2
    
    # 프로세스 종료 확인
    if ps aux | grep 'backend.jar' | grep -v grep > /dev/null; then
        echo "     ⚠️  프로세스가 아직 실행 중, 강제 종료..."
        pkill -9 -f 'backend.jar'
        sleep 1
    fi
    
    # backend 디렉토리로 이동
    cd ~/backend
    
    # 최신 JAR 파일 자동 탐지
    echo "  → 최신 JAR 파일 탐지 중..."
    LATEST_JAR=$(ls -t ~/backend/release/backend-*.jar | head -1)
    echo "     최신 파일: $LATEST_JAR"
    
    # 심볼릭 링크 생성
    echo "  → 심볼릭 링크 생성 중..."
    ln -sf $LATEST_JAR ~/backend/backend.jar
    ls -lh ~/backend/backend.jar
    
    # 새 JAR 실행
    echo "  → 새 JAR 실행 중..."
    nohup java -jar ~/backend/backend.jar > ~/backend/backend.log 2>&1 &
    
    # 프로세스 시작 대기
    echo "  → 프로세스 시작 대기 (5초)..."
    sleep 5
    
    # 프로세스 확인
    echo "  → 프로세스 확인 중..."
    if ps aux | grep 'backend.jar' | grep -v grep > /dev/null; then
        echo "     ✅ 프로세스 실행 중"
        ps aux | grep 'backend.jar' | grep -v grep | awk '{print "     PID: " $2}'
    else
        echo "     ❌ 프로세스 시작 실패!"
        echo "     로그 확인:"
        tail -20 ~/backend/backend.log
        exit 1
    fi
    
    # 헬스체크
    echo "  → 헬스체크 중..."
    for i in {1..10}; do
        if curl -fsS http://localhost:8080/actuator/health > /dev/null 2>&1; then
            echo "     ✅ 헬스체크 성공!"
            break
        else
            if [ $i -eq 10 ]; then
                echo "     ❌ 헬스체크 실패! (10회 시도)"
                echo "     최근 로그:"
                tail -30 ~/backend/backend.log
                exit 1
            fi
            echo "     대기 중... ($i/10)"
            sleep 2
        fi
    done
    
    echo ""
    echo "  [서버] 배포 완료!"
EOF

# 배포 결과 확인
if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "✅ 백엔드 배포 성공!"
    echo "========================================="
    echo "접속 URL: http://$SERVER_IP:8080"
    echo "헬스체크: http://$SERVER_IP:8080/actuator/health"
    echo "배포 시간: $(date '+%Y-%m-%d %H:%M:%S')"
else
    echo ""
    echo "========================================="
    echo "❌ 백엔드 배포 실패!"
    echo "========================================="
    exit 1
fi
