package must

// Succeed panics if err is not nil
func Succeed(err error) {
	if err != nil {
		panic(err)
	}
}
