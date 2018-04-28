//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include <stdint.h>

int csr_check(uint32_t mask);
int csr_get_active_config(uint32_t *config);
