package scripts_test

import (
	"bufio"
	"fmt"
	"github.com/ProtonMail/gopenpgp/v2/crypto"
	yaml "gopkg.in/yaml.v2"
	"os"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Concourse gpg vars files", func() {

	It("should contain all the keys specified in .gpg-id", func() {
		expectedKeyIds := readFileIntoLines("../../.gpg-id")

		f, err := os.Open("../vars-files/gpg-keys.yml")
		Expect(err).NotTo(HaveOccurred())
		defer f.Close()

		var keyData struct {
			Keys []string `yaml:"gpg_public_keys"`
		}
		err = yaml.NewDecoder(f).Decode(&keyData)
		Expect(err).NotTo(HaveOccurred())

		var concourseKeyIds []string
		for _, k := range keyData.Keys {
			concourseKeyIds = append(concourseKeyIds, extractKeyId(k))
		}

		Expect(concourseKeyIds).To(ConsistOf(expectedKeyIds), "concourse/vars-files/gpg-keys.yml does not match .gpg-id. Have you run `make update_merge_keys`?")
	})
})

func extractKeyId(keyASC string) string {

	key, err := crypto.NewKeyFromArmored(keyASC)
	ExpectWithOffset(1, err).NotTo(HaveOccurred())

	e := key.GetEntity()
	ExpectWithOffset(1, e).NotTo(BeNil())
	ExpectWithOffset(1, e.PrimaryKey).NotTo(BeNil())
	return fmt.Sprintf("%X", e.PrimaryKey.Fingerprint)
}

func readFileIntoLines(filename string) []string {
	f, err := os.Open(filename)
	ExpectWithOffset(1, err).NotTo(HaveOccurred())
	defer f.Close()
	s := bufio.NewScanner(f)
	var lines []string
	for s.Scan() {
		lines = append(lines, s.Text())
	}
	ExpectWithOffset(1, s.Err()).NotTo(HaveOccurred())
	return lines
}
