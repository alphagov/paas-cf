package fakes

type FakeRemoteResource struct {
	ShouldRemainReturns bool

	createCallCount  int
	destroyCallCount int
}

func (resource *FakeRemoteResource) Create() {
	resource.createCallCount += 1
}
func (resource *FakeRemoteResource) Destroy() {
	resource.destroyCallCount += 1
}

func (resource *FakeRemoteResource) ShouldRemain() bool {
	return resource.ShouldRemainReturns
}

func (resource *FakeRemoteResource) CreateCallCount() int {
	return resource.createCallCount
}

func (resource *FakeRemoteResource) DestroyCallCount() int {
	return resource.destroyCallCount
}
