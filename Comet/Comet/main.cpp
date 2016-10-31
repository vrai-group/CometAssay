#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>

using namespace cv;
using namespace std;

int main()
{

	Mat img; //Creo un oggetto di tipo Mat (Matrice)

	img = imread("C:/Users/Lorenzo/GitHub/CometAssay/img1.png");   // Carica l'immagine

	imshow("Test", img); // La visualizza

	waitKey(0);   // Attende finchè non viene premuto un tasto
	return 0;
}