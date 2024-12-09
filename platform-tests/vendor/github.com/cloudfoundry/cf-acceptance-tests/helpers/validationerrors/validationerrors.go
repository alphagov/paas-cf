package validationerrors

type Errors struct {
	errors []error
}

func (e *Errors) Add(err error) {
	e.errors = append(e.errors, err)
}

func (errs Errors) Error() string {
	result := ""
	for i, e := range errs.errors {
		result = result + e.Error()
		if i+1 != len(errs.errors) {
			result += "\n"
		}
	}
	return result
}

func (errs *Errors) Empty() bool {
	return len(errs.errors) == 0
}
