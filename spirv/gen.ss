(import :kaladin/vulkan-auto
	:kaladin/ctypes
	:gerbil/gambit/bytes)

(export #t)

(define (gen-header) '())

(defstruct field-value (value capability))

;; field-values will be a list of (U field-value label arg #f)
(defstruct instruction (opcode-name field-values capability))

(deine make-instruction
       (case-lambda
	 ((opcode-name field-values) (make-instruction opcode-name field-values #f))
	 ((opcode-name field-values capability)
	  (make-instruction opcode-name field-values capability))))

#|
Capabilities

Capabilities a module can declare it uses.

Matrix
Uses OpTypeMatrix.

Shader
Uses Vertex, Fragment, or GLCompute Execution Models.

Geometry
Uses the Geometry Execution Model.

Tessellation
Uses the TessellationControl or TessellationEvaluation Execution Models.

Addresses
Uses physical addressing, non-logical addressing modes.

Kernel
Uses the Kernel Execution Model.
	
Pipes
Uses OpTypePipe, OpTypeReserveId, or pipe instructions.

DeviceEnqueue
Uses OpTypeQueue, OpTypeDeviceEvent, and device side enqueue instructions.

|#
(define matrix-capability "Matrix")
(define shader-capability "Shader")
(define geometry-capability "Geometry")
(define address-capability "Addresses")
(define kernel-capability "Kernel")
(define pipes-capability "Pipes")
(define tessellation-capability "Tessellation")
(define device-enqueue-capability "DeviceEnqueue")


#|
Import an extended set of instructions. It can be later referenced by the Result <id>.

Name is the extended instruction-set’s name string. 
There must be an external specification defining the semantics for this extended 
instruction set.

See Extended Instruction Sets[0] for more information.

[0] - https://www.khronos.org/registry/spir-v/specs/1.0/SPIRV.html#ExtInst
|#
(define glsl-450-instruction-set (make-field-value "GLSL.std.450" #f))

(define (import-instruction-set instruction-set)
  (make-instruction "OpExtInstImport" instruction-set))


#|
Addressing Mode

Logical

Physical32
Indicates a 32-bit module, where the address width is equal to 32 bits.

Physical64
Indicates a 64-bit module, where the address width is equal to 64 bits.
|#

(define logical-addressing-mode (make-field-value "Logical" #f))
(define physical-32-addressing-mode (make-field-value "Physical32" address-capability))
(define physical-64-addressing-mode (make-field-value "Physical64" address-capability))

#|
Memory Mode

Simple
No shared memory consistency issues.

GLSL450
Memory model needed by later versions of GLSL and ESSL. Works across multiple versions.

OpenCL
OpenCL memory model.
|#

(define simple-memory-mode (make-field-value "Simple" shader-capability))
(define glsl-memory-mode (make-field-value "GLSL450" shader-capability))
(define opencl-memory-mode (make-field-value "OpenCl" kernel-capability))


(define (memory-model-instruction addressing-mode memory-mode)
  (make-instruction "OpMemoryModel" (list addressing-mode memory-mode)))

;; (make-memory-model logical-addressing-mode glsl-memory-mode)


#|
Execution Model

Vertex
Vertex shading stage.

TessellationControl
Tessellation control (or hull) shading stage.

TessellationEvaluation
Tessellation evaluation (or domain) shading stage.

Geometry
Geometry shading stage.

Fragment
Fragment shading stage.

GLCompute
Graphical compute shading stage.

Kernel
Compute kernel.
|#
(define vertex-execution-model (make-field-value "Vertex" shader-capability))
(define tessellation-control-execution-model (make-field-value "Tessellation-Control"
							      tessellation-capability))
(define tessellation-evaluation-execution-model
  (make-field-value "TessellationEvaluation" tessellation-capability))
(define geometry-execution-model (make-field-value "Geometry" geometry-capability))
(define fragment-execution-model (make-field-value "Fragment" shader-capability))
(define gl-compute-execution-model (make-field-value "GlCompute" shader-capability))
(define kernel-execution-model (make-field-value "Kernel" kernel-capability))

#|
Entry point

Declare an entry point and its execution model.

Execution Model is the execution model for the entry point and its static call tree. 

lambda-label:
Entry Point must be the Result <id> of an OpFunction instruction.

lambda-name:
Name is a name string for the entry point. 
A module cannot have two OpEntryPoint instructions with the same Execution Model and 
the same Name string.

interface-labels:
Interface is a list of <id> of global OpVariable instructions with either Input or
Output for its Storage Class operand. These declare the input/output interface of the 
entry point. They could be a subset of the input/output declarations of the module, 
and a superset of those referenced by the entry point’s static call tree. 
It is invalid for the entry point’s static call tree to reference such an <id> if it 
was not listed with this instruction.

Interface <id> are forward references. 
They allow declaration of all variables forming an interface for an entry point, 
whether or not all the variables are actually used by the entry point.
|#
(define (entrypoint-instruction execution-model
				entrypoint-lambda-label
				entrypoint-lambda-name . interface-labels)
  (make-instruction "OpEntryPoint"
		    (append (list execution-model entrypoint-lambda-label entrypoint-lambda-name)
			    interface-labels)))

#| 
Execution Mode

Declare the modes an entry point will execute in. Used by OpExecutionMode.

Invocations
Number of times to invoke the geometry stage for each input primitive received. 
The default is to run once for each input primitive. It is invalid to specify a value 
greater than the target-dependent maximum. 
Only valid with the Geometry Execution Model.

SpacingEqual
Requests the tessellation primitive generator to divide edges into a collection of 
equal-sized segments. Only valid with one of the tessellation Execution Models.

SpacingFractionalEven
Requests the tessellation primitive generator to divide edges into an even number of 
equal-length segments plus two additional shorter fractional segments. 
Only valid with one of the tessellation Execution Models.

SpacingFractionalOdd
Requests the tessellation primitive generator to divide edges into an odd number of 
equal-length segments plus two additional shorter fractional segments. 
Only valid with one of the tessellation Execution Models.

VertexOrderCw
Requests the tessellation primitive generator to generate triangles in clockwise order.
Only valid with one of the tessellation Execution Models.


VertexOrderCcw
Requests the tessellation primitive generator to generate triangles in counter-clockwise
order. Only valid with one of the tessellation Execution Models.

PixelCenterInteger
Pixels appear centered on whole-number pixel offsets. 
E.g., the coordinate (0.5, 0.5) appears to move to (0.0, 0.0). 
Only valid with the Fragment Execution Model. 
If a Fragment entry point does not have this set, pixels appear centered at 
offsets of (0.5, 0.5) from whole numbers

OriginUpperLeft
Pixel coordinates appear to originate in the upper left, 
and increase toward the right and downward. 
Only valid with the Fragment Execution Model.

OriginLowerLeft
Pixel coordinates appear to originate in the lower left, 
and increase toward the right and upward. Only valid with the Fragment Execution Model.

EarlyFragmentTests
Fragment tests are to be performed before fragment shader execution. 
Only valid with the Fragment Execution Model.

PointMode
Requests the tessellation primitive generator to generate a point for each distinct 
vertex in the subdivided primitive, rather than to generate lines or triangles. 
Only valid with one of the tessellation Execution Models.

Xfb
This stage will run in transform feedback-capturing mode and this module is responsible 
for describing the transform-feedback setup. See the XfbBuffer, Offset, and XfbStride 
Decorations.

DepthReplacing
This mode must be declared if this module potentially changes the fragment’s depth. 
Only valid with the Fragment Execution Model.

DepthGreater
External optimizations may assume depth modifications will leave the fragment’s depth 
as greater than or equal to the fragment’s interpolated depth value (given by the z 
component of the FragCoord BuiltIn decorated variable). 
Only valid with the Fragment Execution Model.

DepthLess
External optimizations may assume depth modifications leave the fragment’s depth less 
than the fragment’s interpolated depth value, (given by the z component of the 
FragCoord BuiltIn decorated variable). Only valid with the Fragment Execution Model.

DepthUnchanged
External optimizations may assume this stage did not modify the fragment’s depth. 
However, DepthReplacing mode must accurately represent depth modification. 
Only valid with the Fragment Execution Model.

LocalSize
Indicates the work-group size in the x, y, and z dimensions. Only valid with the GLCompute or Kernel Execution Models.

LocalSizeHint
A hint to the compiler, which indicates the most likely to be used work-group size in 
the x, y, and z dimensions. Only valid with the Kernel Execution Model.

InputPoints
Stage input primitive is points. Only valid with the Geometry Execution Model.

InputLines
Stage input primitive is lines. Only valid with the Geometry Execution Model.

InputLinesAdjacency
Stage input primitive is lines adjacency. Only valid with the Geometry Execution Model.

Triangles
For a geometry stage, input primitive is triangles. 
For a tessellation stage, requests the tessellation primitive generator to 
generate triangles. 
Only valid with the Geometry or one of the tessellation Execution Models.

InputTrianglesAdjacency
Geometry stage input primitive is triangles adjacency. 
Only valid with the Geometry Execution Model.

Quads
Requests the tessellation primitive generator to generate quads. 
Only valid with one of the tessellation Execution Models.

Isolines
Requests the tessellation primitive generator to generate isolines. 
Only valid with one of the tessellation Execution Models.

OutputVertices
For a geometry stage, the maximum number of vertices the shader will ever emit in a 
single invocation. 
For a tessellation-control stage, the number of vertices in the output patch produced 
by the tessellation control shader, which also specifies the number of times the 
tessellation control shader is invoked. 
Only valid with the Geometry or one of the tessellation Execution Models.

OutputPoints
Stage output primitive is points. Only valid with the Geometry Execution Model.

OutputLineStrip
Stage output primitive is line strip. Only valid with the Geometry Execution Model.

OutputTriangleStrip
Stage output primitive is triangle strip. Only valid with the Geometry Execution Model.

VecTypeHint
A hint to the compiler, which indicates that most operations used in the entry point are
explicitly vectorized using a particular vector type. The 16 high-order bits of Vector 
Type operand specify the number of components of the vector. The 16 low-order bits of 
Vector Type operand specify the data type of the vector.

These are the legal data type values:
0 represents an 8-bit integer value.
1 represents a 16-bit integer value.
2 represents a 32-bit integer value.
3 represents a 64-bit integer value.
4 represents a 16-bit float value.
5 represents a 32-bit float value.
6 represents a 64-bit float value.

Only valid with the Kernel Execution Model.

ContractionOff
Indicates that floating-point-expressions contraction is disallowed. Only valid with the Kernel Execution Model.

PostDepthCoverage

StencilRefReplacingEXT
|#

(define origin-upper-left-execution-mode (make-field-value "OriginUpperLeft"
							   shader-capability))

;; todo rest execution-mode to be written up as they are used


(define (execution-mode-instruction entrypoint-lambda-label execution-mode)
  (make-instruction "OpExecutionMode" (list entrypoint-lambda-label )))

;;;;;;;;;;;;;;;;;
;; Decorations ;;
;;;;;;;;;;;;;;;;;

#|

BuiltIn:
Apply to an object or a member of a structure type.
Indicates which built-in variable the entity represents. 

|#

(define built-in-decoration (make-field-value "BuiltIn" #f))

#|
Location:
Apply to a variable or a structure-type member. 
Forms the main linkage for Storage Class Input and Output variables:
- between the API and vertex-stage inputs,
- between consecutive programmable stages, or
- between fragment-stage outputs and the API.
Also can tag variables or structure-type members in the UniformConstant Storage Class 
for linkage with the API.
Only valid for the Input, Output, and UniformConstant Storage Classes.
|#

(define location-decoration (make-field-value "Location" shader-capability))

;; todo write rest of the decorations

(define (decorate-instruction label decoration . args)
  (make-instruction "OpDecorate"
		    (append (list label decoration) args)))

;; (decorate-instruction "%outColor" location-decoration 0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Type Declaration Instructions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#|
OpTypeVoid
Declare the void type
|#

(define make-void-type (make-instruction "OpTypeVoid" #f))

#|
OpTypeBool

Declare the Boolean type. Values of this type can only be either true or false. 
There is no physical size or bit pattern defined for these values. 
If they are stored (in conjunction with OpVariable), they can only be used with logical 
addressing operations, not physical, and only with non-externally visible shader 
Storage Classes: Workgroup, CrossWorkgroup, Private, and Function.
|#

(define make-bool-type  (make-instruction "OpTypeBool" #f))

#|
OpTypeInt

Declare a new integer type.

Width specifies how many bits wide the type is. This literal operand is limited to a 
single word. The bit pattern of a signed integer value is two’s complement.

Signedness specifies whether there are signed semantics to preserve or validate.
0 indicates unsigned, or no signedness semantics
1 indicates signed semantics.
In all cases, the type of operation of an instruction comes from the instruction’s 
opcode, not the signedness of the operands.
|#

(define (make-int-type width signedness)
  (make-instruction "OpTypeInt" (list width signedness)))

#|
OpTypeFloat

Declare a new floating-point type.

Width specifies how many bits wide the type is. The bit pattern of a floating-point 
value is as described by the IEEE 754 standard.
|#

(deine (make-float-type width) (make-instruction "OpTypeFloat" (list width)))

#|
OpTypeVector

Declare a new vector type.

Component Type is the type of each component in the resulting type. 
It must be a scalar type.

Component Count is the number of components in the resulting type. 
It must be at least 2.

Components are numbered consecutively, starting with 0.
|#

(define (make-vector-type component-type count)
  (make-instruction "OpTypeVector" (list component-type count)))

#|

OpTypeMatrix

Declare a new matrix type.

Column Type is the type of each column in the matrix. It must be vector type.

Column Count is the number of columns in the new matrix type. It must be at least 2.

Matrix columns are numbered consecutively, starting with 0. 
This is true independently of any Decorations describing the memory layout of a 
matrix (e.g., RowMajor or MatrixStride).
|#

(define (make-matrix-type column-type column-count)
  (make-instruction "OpTypeMatrix" (list column-type column-count) matrix-capability))

#|
OpTypeImage

Declare a new image type. Consumed, for example, by OpTypeSampledImage. 
This type is opaque: values of this type have no defined physical size or bit pattern.

Sampled Type is the type of the components that result from sampling or reading from 
this image type. 
Must be a scalar numerical type or OpTypeVoid.

Dim is the image dimensionality (Dim).

Depth is whether or not this image is a depth image. (Note that whether or not depth 
comparisons are actually done is a property of the sampling opcode, not of this type 
declaration.)
0 indicates not a depth image
1 indicates a depth image
2 means no indication as to whether this is a depth or non-depth image

Arrayed must be one of the following indicated values:
0 indicates non-arrayed content
1 indicates arrayed content

MS must be one of the following indicated values:
0 indicates single-sampled content
1 indicates multisampled content

Sampled indicates whether or not this image will be accessed in combination with a 
sampler, and must be one of the following values:
0 indicates this is only known at run time, not at compile time
1 indicates will be used with sampler
2 indicates will be used without a sampler (a storage image)

Image Format is the Image Format, which can be Unknown, depending on the client API.

If Dim is SubpassData, Sampled must be 2, Image Format must be Unknown, and the 
Execution Model must be Fragment.

Access Qualifier is an image Access Qualifier.
|#

(define (make-image-type sampled-type dim depth arrayed multi-sampling sampled format
			 access-qualifier)
  (make-instruction "OpTypeImage" (list scaled-type dim depth arrayed multi-sampling
					sampled format access-qualifier)))

#|
OpTypeSampler

Declare the sampler type. Consumed by OpSampledImage. 
This type is opaque: values of this type have no defined physical size or bit pattern.
|#

(define (make-sampler-type) (make-instruction "OpTypeSampler" #f))

#|
OpTypeSampledImage

Declare a sampled image type, the Result Type of OpSampledImage, 
or an externally combined sampler and image. 
This type is opaque: values of this type have no defined physical size or bit pattern.

Image Type must be an OpTypeImage. It is the type of the image in the combined 
sampler and image type.
|#

(define (make-sampled-image-type image-type) (make-instruction "OpTypeSampledImage" #f))

#|
OpTypeArray

Declare a new array type: a dynamically-indexable ordered aggregate of elements all 
having the same type.

Element Type is the type of each element in the array.

Length is the number of elements in the array. It must be at least 1. Length must come 
from a constant instruction of an integer-type scalar whose value is at least 1.

Array elements are number consecutively, starting with 0.
|#

(define (make-array-type element-type length)
  (make-instruction "OpTypeArray" (list element-type length)))

#|

OpTypeRuntimeArray

Declare a new run-time array type. Its length is not known at compile time.

Element Type is the type of each element in the array. It must be a concrete type.

See OpArrayLength for getting the Length of an array of this type.

Objects of this type can only be created with OpVariable using the Uniform Storage Class.
|#

(define (make-runtime-array-type element-type)
  (make-instruction "OpTypeRuntimeArray" (list element-type) shader-capability))

#|
OpTypeStruct

Declare a new structure type: an aggregate of zero or more potentially heterogeneous 
members.

Member N type is the type of member N of the structure. 
The first member is member 0, the next is member 1, …

If an operand is not yet defined, it must be defined by an OpTypePointer, 
where the type pointed to is an OpTypeStruct.
|#

(define (make-struct-type . types) (make-instruction "OpTypeStruct" types))

#|
OpTypeOpaque

Declare a structure type with no body specified.

type-name:
The name of the opaque type.
|#

(define (make-opaque-type type-name)
  (make-instruction "OpTypeOpaque" #f kernel-capability))

#|

OpTypePointer

Declare a new pointer type.

Storage Class is the Storage Class of the memory holding the object pointed to. 
If there was a forward reference to this type from an OpTypeForwardPointer, the 
Storage Class of that instruction must equal the Storage Class of this instruction.

Type is the type of the object pointed to.
|#

(define (make-pointer-type storage-class type)
  (make-instruction "OpTypePointer" (list storage-class type)))

#|
OpTypeFunction

Declare a new function type.

OpFunction will use this to declare the return type and parameter types of a function. 
OpFunction is the only valid use of OpTypeFunction.

Return Type is the type of the return value of functions of this type. It must be a 
concrete or abstract type, or a pointer to such a type. 
If the function has no return value, Return Type must be OpTypeVoid.

Parameter N Type is the type <id> of the type of parameter N.
|#

(define (make-function-type return-type . parameter-types)
  (make-instruction "OpTypeFunction" (append (list return-type) parameter-types)))

#|
OpTypeEvent

Declare an OpenCL Event type
|#

(define (make-event-type) (make-instruction "OpTypeEvent" #f kernel-capability))

#|
OpTypeDeviceEvent

Declare an OpenCL device-side event type.
|#

(define (make-device-event-type)
  (make-instruction "OpTypeDeviceEvent" #f device-enqueue-capability))

#|
OpTypeReserveId

Declare an OpenCL reservation id type.
|#

(define (make-reservation-type) (make-instruction "OpTypeReserveId" #f pipes-capability))

#|
OpTypeQueue

Declare an OpenCL queue type
|#

(define (make-queue-type) (make-instruction "OpTypeQueue" #f device-enqueue-capability))

#|
OpTypePipe

Declare an OpenCL pipe type

qualifier is the pipe access qualifier
|#

(define (make-pipe-type qualifier)
  (make-instruction "OpTypePipe" (list qualifier) pipes-capability))

#|
OpTypeForwardPointer

Declare the Storage Class for a forward reference to a pointer.

Pointer Type is a forward reference to the result of an OpTypePointer. The type of 
object the pointer points to is declared by the OpTypePointer instruction, not this 
instruction. Subsequent OpTypeStruct instructions can use Pointer Type as an operand.

Storage Class is the Storage Class of the memory holding the object pointed to.
|#

(define (make-forward-pointer-type pointer-type storage-class)
  (make-instruction "OpTypeForwardPointer"
		    (list pointer-type storage-class)
		    address-capability))




(define (spirv->shader-module logical-device spirv-path)  
  (let* ((shader-module-info  (spirv->VkShaderModuleCreateInfo spirv-path))
	 (shader-module (make-VkShaderModule)))
    (cond
     ((fxzero? (vkCreateShaderModule logical-device shader-module-info #f shader-module))
      shader-module)
     (else (error "cannot create shader module from spirv path")))))