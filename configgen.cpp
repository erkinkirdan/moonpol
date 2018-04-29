#include <iostream>
#include <fstream>
#include <cstdlib>
#include <math.h>

using namespace std;

int main(int argc, char *argv[])
{
	ofstream outfile;
        outfile.open("config");
        bool cont = true;
	int prefix = atoi(argv[1]);
	if (prefix < 9) {
		int a = 0;
		while(cont) {
			outfile << a << ".0.0.0/" << prefix << "\t" <<
				argv[2] << endl;
			a = a + pow(2, (8 - prefix));
			if (a == 256)
				cont = false;
		}
	}
	else if (prefix < 17) {
		int a = 0;
		int b = 0;
		while(cont) {
			outfile << a << "." << b << ".0.0/" << prefix <<
				"\t" << argv[2] << endl;
			b = b + pow(2, (16 - prefix));
			if (b == 256) {
				b = 0;
				a++;
				if (a == 256)
					cont = false;
			}
		}
	}
	else if (prefix < 25) {
		int a = 0;
		int b = 0;
		int c = 0;
		while(cont) {
			outfile << a << "." << b << "." << c << ".0/" <<
				prefix << "\t" << argv[2] << endl;
			c = c + pow(2, (24 - prefix));
			if (c == 256) {
				c = 0;
				b++;
				if (b == 256) {
					b = 0;
					a++;
					if (a == 256)
						cont = false;
				}
			}
		}
	}
	else {
		int a = 0;
		int b = 0;
		int c = 0;
		int d = 0;
		while(cont) {
			outfile << a << "." << b << "." << c << "." << d <<
				"/" << prefix << "\t" << argv[2] << endl;
			d = d + pow(2, (32 - prefix));
			if (d == 256) {
				d = 0;
				c++;
				if (c == 256) {
					c = 0;
					b++;
					if (b == 256) {
						b = 0;
						a++;
						if (a == 256)
							cont = false;
					}
				}
			}
		}
	}
	outfile.close();
	return 0;
}

