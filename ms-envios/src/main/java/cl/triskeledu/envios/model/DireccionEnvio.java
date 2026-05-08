package cl.triskeledu.envios.model;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
    name = "direccion_envio",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_direccion_envio_codigo_pedido", columnNames = "codigo_pedido")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DireccionEnvio {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "codigo_pedido", referencedColumnName = "codigo_pedido", nullable = false, unique = true)
    private PedidoProy pedido;

    @Column(name = "direccion", nullable = false, length = 255)
    private String direccion;

    @Column(name = "ciudad", nullable = false, length = 100)
    private String ciudad;

    @Column(name = "codigo_postal", nullable = true, length = 10)
    private String codigoPostal;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof DireccionEnvio)) return false;
        DireccionEnvio that = (DireccionEnvio) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
