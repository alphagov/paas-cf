package main

func ArithmeticMean(data []int64) (float64, bool) {
	count := len(data)
	if count <= 0 {
		return 0, false
	}
	sum := int64(0)
	for _, hit := range data {
		sum += hit
	}
	return float64(sum) / float64(count), true
}
