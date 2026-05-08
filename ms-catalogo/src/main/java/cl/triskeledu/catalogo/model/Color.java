package cl.triskeledu.catalogo.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "color")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Color {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sku", referencedColumnName = "sku", nullable = false)
    private Producto producto;

    @Column(name = "nombre_color", nullable = false, length = 50)
    private String nombreColor;

    @Column(name = "hex_code", nullable = true, length = 7)
    private String hexCode;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Color)) return false;
        Color that = (Color) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
