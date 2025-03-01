import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'sound_manager.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const double maxJumpHeight = 0.4;  // 降低最大跳躍高度
  static const double dinoBaseY = 0.82;  // 從 0.85 改為 0.82，讓恐龍往上一點
  static double dinoY = 0;
  double time = 0;
  double height = 0;
  double initialHeight = 0;
  bool isJumping = false;
  bool isGameOver = false;
  bool isGameStarted = false;  // 新增遊戲開始狀態
  static const int maxScore = 99999;  // 新增：最高分數限制
  int score = 0;
  int timeElapsed = 0;  // 新增：計時器計數
  double cactusX = 1;
  Timer? timer;
  int numberOfCactus = 1;  // 新增：當前仙人掌數量
  final Random random = Random();  // 新增：隨機數生成器

  // 新增圖片尺寸常數
  static const double dinoWidth = 60;
  static const double dinoHeight = 60;
  static const double cactusWidth = 40;
  static const double cactusHeight = 60;

  void startGame() {
    setState(() {
      isGameOver = false;
      isGameStarted = true;  // 設置遊戲開始狀態
      score = 0;
      dinoY = 0;
      cactusX = 1;
      time = 0;
      isJumping = false;
      numberOfCactus = random.nextInt(3) + 1;  // 隨機生成1-3個仙人掌
      timeElapsed = 0;  // 重置計時器計數
    });
    
    timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!isGameStarted) {  // 如果遊戲還沒開始，不執行更新
        timer.cancel();
        return;
      }
      
      // 更新分數（每0.5秒加1分）
      timeElapsed++;
      if (timeElapsed % 10 == 0) {  // 50ms * 10 = 500ms = 0.5秒
        setState(() {
          if (score < maxScore) {
            score++;
          }
        });
      }
      
      if (isJumping) {  // 只有在跳躍狀態才更新時間和高度
        time += 0.05;
        // 調整跳躍參數，降低跳躍高度
        height = -2.5 * time * time + 1.5 * time;  // 降低初始速度
        
        // 限制最大跳躍高度
        if (height > maxJumpHeight) {
          height = maxJumpHeight;
        }
      }
      
      setState(() {
        // 修改地板碰撞檢測
        if (height <= 0) {  // 修改：確保恐龍不會飛走
          dinoY = 0;
          isJumping = false;
          time = 0;
          height = 0;
        } else if (isJumping) {  // 只有在跳躍狀態才更新恐龍高度
          // 確保恐龍Y軸位置在合理範圍內
          dinoY = -height;  // 修改：使用負值來表示向上的移動
          if (dinoY < -maxJumpHeight) {
            dinoY = -maxJumpHeight;
          }
        }

        cactusX -= 0.05;
        if (cactusX < -1.2) {
          resetCactus();  // 使用新的重置方法
        }

        if (checkCollision()) {
          gameOver();
        }
      });
    });
  }

  void jump() {
    if (!isJumping) {
      time = 0;
      initialHeight = dinoY;
      isJumping = true;
      SoundManager.playJumpSound();  // 播放跳躍音效
    }
  }

  bool checkCollision() {
    for (int i = 0; i < numberOfCactus; i++) {
      double currentCactusX = cactusX + (i * 0.12);
      
      // 更新碰撞檢測位置以匹配新的Y軸位置
      double dinoLeft = -0.2 - (60 / MediaQuery.of(context).size.width);
      double dinoRight = -0.2 + (60 / MediaQuery.of(context).size.width);
      double dinoTop = (dinoBaseY + dinoY) - (60 / MediaQuery.of(context).size.height);
      double dinoBottom = dinoBaseY + dinoY;

      double cactusLeft = currentCactusX - (35 / MediaQuery.of(context).size.width);
      double cactusRight = currentCactusX + (35 / MediaQuery.of(context).size.width);
      double cactusTop = 0.85 - (70 / MediaQuery.of(context).size.height);
      double cactusBottom = 0.85;

      // 檢查碰撞
      bool horizontalCollision = dinoRight > cactusLeft && dinoLeft < cactusRight;
      bool verticalCollision = dinoBottom > cactusTop && dinoTop < cactusBottom;

      if (horizontalCollision && verticalCollision) {
        return true;
      }
    }
    return false;
  }

  void resetCactus() {
    setState(() {
      cactusX = 1.2;
      numberOfCactus = random.nextInt(3) + 1;  // 重新隨機生成仙人掌數量
      // 移除這裡的 score++ 因為現在用時間計分
    });
  }

  void gameOver() {
    timer?.cancel();
    setState(() {
      isGameOver = true;
      isGameStarted = false;  // 遊戲結束時重置開始狀態
    });
  }

  @override
  void initState() {
    super.initState();
    // 移除自動開始遊戲
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        if (isGameStarted && !isGameOver) {  // 只有在遊戲開始且未結束時才能跳躍
          jump();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF87CEEB),  // 天空藍
                Color(0xFFE0F6FF),  // 淺藍色
              ],
            ),
          ),
          child: Center(
            child: Stack(
              children: [
                // 分數顯示
                Container(
                  alignment: const Alignment(0, -0.9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      'Score: ${score.toString().padLeft(5, '0')}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF444444),
                      ),
                    ),
                  ),
                ),
                
                // 修改地板設計
                Align(
                  alignment: const Alignment(0, 0.9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 草地層
                      Container(
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Color(0xFF90CF5B),  // 草地的顏色
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFF7BBF44),  // 草地邊緣的深色
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      // 泥土層
                      Container(
                        height: 25,
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B4513),  // 泥土的顏色
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF8B4513),  // 泥土顏色
                              Color(0xFF654321),  // 較深的泥土顏色
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 恐龍
                Container(
                  alignment: Alignment(-0.2, dinoBaseY + dinoY),  // 使用新的基準Y軸位置
                  child: SizedBox(
                    height: 60,  // 恢復恐龍原始大小
                    width: 60,
                    child: Image.asset(
                      'assets/images/dino.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                // 仙人掌組合
                for (int i = 0; i < numberOfCactus; i++)
                  Container(
                    alignment: Alignment(cactusX + (i * 0.12), 0.85),  // 使用相同的Y軸位置
                    child: SizedBox(
                      height: 70,
                      width: 35,
                      child: Image.asset(
                        'assets/images/cactus.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                if (!isGameStarted && !isGameOver)  // 顯示開始按鈕
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Dino Run',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF444444),
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black26,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            'Start Game',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isGameOver)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Game Over',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF444444),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Final Score: ${score.toString().padLeft(5, '0')}',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: startGame,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'Play Again',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
