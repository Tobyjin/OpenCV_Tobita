import gab.opencv.*;

import java.awt.Rectangle;
import processing.video.*;

/** importここまで */

//OpenCV for Processingのオブジェクト
OpenCV opencv;

//カメラ映像をキャプチャーするオブジェクト
Capture capture;

// 認識した顔の範囲を表す矩形の配列
Rectangle[] faces;

// 画像のコントラストの調整値
int contrast_value    = 0;

//明るさの調整値
int brightness_value  = 0;

//顔の中心座標
int center_x = 0;
int center_y = 0;

//余白の座標
int margin_x = 5;
int margin_y = 5;

//枠のカウント
int frame_cnt = 0;

int flash_cnt = 0;
int index_num=0;

//半径
float d_radius = 100.0;

//開始リスト
ArrayList<Integer> start_list = new ArrayList<Integer>();
//帯リスト
ArrayList<Integer> band_list = new ArrayList<Integer>();
ArrayList<Float> random_list = new ArrayList<Float>();
//集中線を作る三角形のリスト
ArrayList<Integer> alpha_list = new ArrayList<Integer>();

void setup() {
  int tmp_start, tmp_band, tmp_margin;
  int tmp_flag = 1;
  int cnt = 0;
  
  //処理解像度
  opencv = new OpenCV(this, 320, 240);
    opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  
  //画面の大きさ
  size(opencv.width, opencv.height);
  //フレームレート
   frameRate(24);
  
  //学習データを指定(正面を向いた顔)

  //キャプチャー解像度
 capture = new Capture(this, width, height);
 //カメラ映像のキャプチャー開始

 capture.start();
  
  // プリント使用
  println( "コントラストを変更するには、このスケッチウィンドウ内のX軸上でマウスをドラッグする" );
  println( "明るさを変更するには、このスケッチウィンドウ内のY軸上でマウスをドラッグする" );

//間隔を適切に調整して繰り返し描画
  while (cnt < width*2+height*2) {
    //集中線のパーツである三角形をつくります。
    //ランダムに底辺の長さを設定し、3点A、B、Cを通る三角形を描画します。
    tmp_start = cnt + (int)random(0, 10); //三角形を描画するために開始
    tmp_band = (int)random(5, 15); //三角形の辺の長さ
    tmp_margin = (int)random(20, 30); //三角形の余白

    start_list.add(tmp_start);
    band_list.add(tmp_band);
    random_list.add(random(0, 10));
    alpha_list.add(tmp_flag*70+70);
    //println(tmp_flag*50+50 +"   "+tmp_flag);

    cnt = tmp_start + tmp_band + tmp_margin;
    tmp_flag = (tmp_flag+1)%2;
  }
}




void draw() {
  // カメラ映像のキャプチャーが有効な場合のみ、
  // カメラ映像を読み込む。
    if (capture.available() == true)
  {
    capture.read();
  }
  
  float start_x, start_y, end_x, end_y;
  float top_x, top_y;
  float[] top_array = new float[2];
  int face_r = 100;
  int flag = 0;
  int tmp = 0;
  float r_seed = 0;
  int tri_alpha = 0; 
  float face_len = 0.0;
  float[] face_len_array = new float[1];
  float tmp_face_len = 0.0;

  // カメラ映像を読み込んだ結果を、OpenCVに渡します。
  opencv.loadImage(capture);
  
  // OpenCVを使ってパターン認識を実行して、
  // 認識された顔の矩形範囲の配列を返り値として受け取ります。
  faces = opencv.detect();

  //指定された値を用いて画像のコントラストと明るさを調整
  opencv.contrast( contrast_value );
  opencv.brightness( brightness_value );

  // display the image
  image(opencv.getInput(), 0, 0);

  // draw face area(s)
  noFill();
  stroke(255, 0, 0);
  for ( int i=0; i<faces.length; i++ ) {
    //rect( faces[i].x, faces[i].y, faces[i].width, faces[i].height ); 
    center_x = faces[i].x+faces[i].width/2;
    center_y = faces[i].y+faces[i].height/2;
     face_len = faces[i].width*1.25;
  }

  //三角形を描画
  for (int j=0; j<start_list.size(); j++) {
    //各三角形の点のセット座標
    tmp = start_list.get(j);
    r_seed = random_list.get(j);
    tri_alpha = alpha_list.get(j);
    if (tmp < width) {
      start_x = tmp;
      end_x = start_x + band_list.get(j);
      start_y = end_y = 0;
      flag = 0;
    }
    else if (tmp >= width && tmp < width+height) {
      start_x = end_x = width;
      start_y = tmp - width;
      end_y = start_y + band_list.get(j);
      flag = 1;
    }
    else if (tmp >= width+height && tmp < width*2+height) {
      start_x = tmp - (width+height);
      end_x = start_x - band_list.get(j);
      start_y = end_y = height;
      flag = 2;
    }
    else {
      start_x = end_x = 0;
      start_y = tmp - (width*2+height);
      end_y = start_y - band_list.get(j);
      flag = 3;
    }
    //if (j == 0)flag = 4;

    top_array = getTopVertex(start_x, start_y, face_len, r_seed, flag);
    top_x = top_array[0];
    top_y = top_array[1];

    color c = color(255, 255, 255);
    stroke(c, tri_alpha);
    fill(c, tri_alpha);
    //triangle(start_x, start_y, end_x, end_y, center_x, center_y);
    if (flash_cnt > 0)triangle(start_x, start_y, end_x, end_y, top_x, top_y);
    //if (flag==0)triangle(start_x, start_y, end_x, end_y, top_x, top_y);
    frame_cnt = (frame_cnt+1)%face_len_array.length;
  }
  flash_cnt = (flash_cnt+1)%3;
  //flash_cnt = 1;
  //println(flash_cnt);
}

float[] getTopVertex(float x, float y, float f_len, float r, int fl) {
  float[] dst = new float[2]; //0:x, 1:y
  float tmp_x=0.0, tmp_y=0.0;
  float len=0.0, s_ratio=0.0;
  float ratio=0.0;

  if (f_len == 0)ratio = 0.0;
  else {
    if (f_len < d_radius)f_len = d_radius;

    len = sqrt(sq(x-center_x)+sq(y-center_y));
    s_ratio = (len-f_len)/len*100.0;
    ratio = random(s_ratio-r, s_ratio+r);
  }

  if (fl == 0) {
    if (abs(x-center_x) < margin_x) {
      tmp_x = center_x;
      tmp_y = center_y * ratio/100;
    }
    else {
      tmp_x = center_x + (x-center_x)*(100-ratio)/100;
      tmp_y = center_y/(center_x-x)*(tmp_x-x);
    }
  }
  else if (fl == 1) {
    if (abs(y-center_y) < margin_y) {
      tmp_x = center_x*(200-ratio);
      tmp_y = center_y;
    }
    else {
      tmp_y = center_y + (y-center_y)*(100-ratio)/100;
      tmp_x = (center_x-width)/(center_y-y)*(tmp_y-y)+width;
    }
  }
  else if (fl == 2) {
    if (abs(x-center_x) < margin_x) {
      tmp_x = center_x;
      tmp_y = center_y*(200-ratio);
    }
    else {
      tmp_x = center_x + (x-center_x)*(100-ratio)/100;
      tmp_y = (center_y-height)/(center_x-x)*(tmp_x-x)+height;
    }
  }
  else if (fl == 3) {
    if (abs(y-center_y) < margin_y) {
      tmp_y = center_y;
      tmp_x = center_x*ratio/100;
    }
    else {
      tmp_y = center_y + (y-center_y)*(100-ratio)/100;
      tmp_x = (center_x)/(center_y-y)*(tmp_y-y);
    }
  }
  else if (fl == 4) {
    if (abs(x-center_x) < margin_x) {
      tmp_x = center_x;
      tmp_y = center_y * ratio/100;
    }
    else {
      tmp_x = center_x + (x-center_x)*(100-ratio)/100;
      tmp_y = center_y/(center_x-x)*(tmp_x-x);
    }
  }
  /*if (fl == 4) {
    float aa = center_x-x;
    float bb = tmp_x-x;
    float cc = center_x-x;
    float dd = (float)(center_y/(center_x-x));
    println("s_x:"+center_x+" s_y:"+center_y+ " f_len:"+f_len+" len:"+len+" r:"+ratio+" fr:"+s_ratio);
  }*/

  dst[0] = tmp_x;
  dst[1] = tmp_y;

  return dst;
}

void mousePressed() {
  String y, m, d, h, mm, s;

  y = String.valueOf(year());
  m = String.valueOf(month());
  d = String.valueOf(day());
  h = String.valueOf(hour());
  mm = String.valueOf(minute());
  s = String.valueOf(second());

  String mystr="images/"+y+m+d+h+mm+s+".jpg";
  save(mystr);
  index_num++;
}
void keyPressed() {
  if(key == 'p' || key == 'P') {
    save("screenshot .png");
  }
  if(key == 'e' || key == 'E') {
    exit();
  }
}
