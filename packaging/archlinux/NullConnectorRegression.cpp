// Standalone regression for upstream fc77bd58, built with -fno-access-control.
// Calls the real library without opening a GPU or changing the desktop.
#include <aquamarine/backend/DRM.hpp>

using namespace Aquamarine;
using namespace Hyprutils::Memory;

int main() {
    auto backend = CSharedPointer<CBackend>(new CBackend());
    backend->session = makeShared<CSession>();
    auto drm = CSharedPointer<CDRMBackend>(new CDRMBackend(backend));
    drm->self = drm;

    // The first connector has been released during teardown; the next is live.
    drm->connectors.emplace_back(nullptr);
    drm->connectors.emplace_back(makeShared<SDRMConnector>());
    drm->flushAsyncCommitEvents();

    // Clear the synthetic list before normal destruction (no real outputs).
    drm->connectors.clear();
}
