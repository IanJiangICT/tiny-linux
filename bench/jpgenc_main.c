#include <stdio.h>
#include "jpgenc_inc.h"

static uint8_t *load_image(int *width, int *height);

#include "jpgenc_data.c"

static int jpgenc_t_pass(void) { return 1; }
static int jpgenc_t_fail(void) { return 0; }

int main (int argc, char *argv[])
{
	int w, h;
	uint8_t *img;
	int jpg_test_len;
	int error_cnt = 0;
	jpec_enc_t *e;

	img = load_image(&w, &h);
	e = jpec_enc_new(img, w, h);

	printf("Starting %s with image %d x %d\n", argv[0], w, h);

	jpec_enc_run(e, &jpg_test_len);

	jpec_enc_del(e);
	if (error_cnt == 0) {
		printf("%s test Success\n", argv[0]);
		return jpgenc_t_pass();
	} else {
		printf("%s test Failed\n", argv[0]);
		return jpgenc_t_fail();
	}
}

static uint8_t *load_image(int *width, int *height)
{
	*width = image_width;
	*height = image_height;
	return image_data;
}

