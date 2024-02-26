#include "include/hello.h"
#include "../OpenUSD/include/pxr/pxr.h"
#include "../OpenUSD/include/pxr/usd/usd/stage.h"
#include "../OpenUSD/include/pxr/usd/usdGeom/sphere.h"
#include "../OpenUSD/include/pxr/usd/usdGeom/xform.h"
#include <iostream>

extern "C" {

void helloWorld() { std::cout << "Hello World!" << std::endl; }

void printPrimInfo() { std::cout << PXR_VERSION << std::endl; }

void createStage() {
    pxr::UsdStageRefPtr stage = pxr::UsdStage::CreateInMemory("/tmp/stage.usd");
    pxr::UsdGeomXform xform =
      pxr::UsdGeomXform::Define(stage, pxr::SdfPath("/myXform"));
    pxr::UsdGeomSphere sphere =
      pxr::UsdGeomSphere::Define(stage, pxr::SdfPath("/myXform/mySphere"));
    sphere.GetPrim().SetMetadata(
            pxr::SdfFieldKeys->Comment,
            "I am a comment"
    );

    auto *result = new std::string();
    stage->GetRootLayer()->ExportToString(result);
    std::cout << *result << std::endl;

    delete result;
    result = nullptr;
}

} // extern "C"
