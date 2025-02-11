using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class TerrainMeshGenerator : MonoBehaviour {
    public int gridSize = 64;  // Number of vertices along one axis
    public float terrainSize = 100f;

    void Start() {
        Mesh mesh = new Mesh();
        Vector3[] vertices = new Vector3[(gridSize + 1) * (gridSize + 1)];
        int[] triangles = new int[gridSize * gridSize * 6];

        // Generate vertices
        for (int z = 0, i = 0; z <= gridSize; z++) {
            for (int x = 0; x <= gridSize; x++, i++) {
                float xPos = (x / (float)gridSize - 0.5f) * terrainSize;
                float zPos = (z / (float)gridSize - 0.5f) * terrainSize;
                // Height can be modified later (e.g., via a heightmap or noise)
                vertices[i] = new Vector3(xPos, 0, zPos);
            }
        }

        // Generate triangles (two per quad)
        int vert = 0;
        int tris = 0;
        for (int z = 0; z < gridSize; z++) {
            for (int x = 0; x < gridSize; x++) {
                triangles[tris + 0] = vert + 0;
                triangles[tris + 1] = vert + gridSize + 1;
                triangles[tris + 2] = vert + 1;
                triangles[tris + 3] = vert + 1;
                triangles[tris + 4] = vert + gridSize + 1;
                triangles[tris + 5] = vert + gridSize + 2;
                vert++;
                tris += 6;
            }
            vert++;
        }

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();

        GetComponent<MeshFilter>().mesh = mesh;
    }
}
