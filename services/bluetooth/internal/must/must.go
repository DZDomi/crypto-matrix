package must

import log "github.com/sirupsen/logrus"

// Succeed panics if err is not nil
func Succeed(err error) {
	if err != nil {
		log.Panic(err)
	}
}
