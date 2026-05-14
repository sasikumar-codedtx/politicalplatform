/**
 * Browser-side face landmark detection via MediaPipe Tasks Vision.
 *
 * Detects 478 landmarks per face (eyes, mouth, eyebrows, jawline, etc.) and
 * returns the mouth bbox the canvas animator uses. Runs once per photo —
 * the detector itself is a module-level singleton so we don't reload the
 * WASM + model every time an avatar is selected.
 *
 * Why MediaPipe over face-api.js: 478 landmarks vs 68, smaller model
 * (~3 MB vs ~10 MB), actively maintained by Google, modern API. Runs on
 * any laptop, no GPU.
 */
const WASM_URL  = 'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision/wasm'
const MODEL_URL = 'https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/latest/face_landmarker.task'

// MediaPipe face-mesh indices for key features.
// https://github.com/google-ai-edge/mediapipe/blob/master/mediapipe/python/solutions/face_mesh_connections.py
const MOUTH_OUTLINE_INDICES = [
  61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291,   // lower lip outer
  308, 324, 318, 402, 317, 14, 87, 178, 88, 95, 78,    // lower lip inner
  191, 80, 81, 82, 13, 312, 311, 310, 415, 308,        // upper lip inner
  185, 40, 39, 37, 0, 267, 269, 270, 409, 291,         // upper lip outer
]
const LEFT_EYE_INDICES  = [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246]
const RIGHT_EYE_INDICES = [263, 249, 390, 373, 374, 380, 381, 382, 362, 466, 388, 387, 386, 385, 384, 398]

let detectorPromise = null

async function getDetector() {
  if (detectorPromise) return detectorPromise
  detectorPromise = (async () => {
    const { FilesetResolver, FaceLandmarker } = await import('@mediapipe/tasks-vision')
    const fileset = await FilesetResolver.forVisionTasks(WASM_URL)
    return FaceLandmarker.createFromOptions(fileset, {
      baseOptions: { modelAssetPath: MODEL_URL },
      runningMode: 'IMAGE',
      numFaces: 1,
      outputFaceBlendshapes: false,
      outputFacialTransformationMatrixes: false,
    })
  })().catch((err) => {
    // If MediaPipe can't load (CDN blocked, etc.) we reset the promise so a
    // later retry can attempt again, and propagate the error to the caller.
    detectorPromise = null
    throw err
  })
  return detectorPromise
}

function bboxFromLandmarks(landmarks, indices) {
  let xMin = 1, xMax = 0, yMin = 1, yMax = 0
  for (const i of indices) {
    const p = landmarks[i]
    if (!p) continue
    if (p.x < xMin) xMin = p.x
    if (p.x > xMax) xMax = p.x
    if (p.y < yMin) yMin = p.y
    if (p.y > yMax) yMax = p.y
  }
  return {
    cx: (xMin + xMax) / 2,
    cy: (yMin + yMax) / 2,
    w:  Math.max(0, xMax - xMin),
    h:  Math.max(0, yMax - yMin),
  }
}

/**
 * Detects the face in the given <img> element and returns normalized
 * bboxes for mouth + eyes (all values 0..1). Returns null if no face was
 * detected; throws if the detector itself fails to initialize.
 */
export async function detectFaceBoxes(imgElement) {
  const det = await getDetector()
  const result = det.detect(imgElement)
  if (!result.faceLandmarks || result.faceLandmarks.length === 0) return null
  const lm = result.faceLandmarks[0]
  return {
    mouth: bboxFromLandmarks(lm, MOUTH_OUTLINE_INDICES),
    leftEye:  bboxFromLandmarks(lm, LEFT_EYE_INDICES),
    rightEye: bboxFromLandmarks(lm, RIGHT_EYE_INDICES),
  }
}
