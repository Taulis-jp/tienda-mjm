package cl.triskeledu.devolucion.model;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "devolucion",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_devolucion_codigo_pedido", columnNames = "codigo_pedido")
    }
)
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Devolucion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "codigo_pedido", referencedColumnName = "codigo_pedido", nullable = false, unique = true)
    private PedidoProy pedido;

    @Column(name = "email", nullable = false, length = 100)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado", nullable = false, length = 15)
    @Builder.Default
    private EstadoDevolucion estado = EstadoDevolucion.solicitada;

    @CreatedDate
    @Column(name = "fecha", nullable = false, updatable = false)
    private LocalDateTime fecha;

    @OneToOne(mappedBy = "devolucion", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Motivo motivo;

    @OneToOne(mappedBy = "devolucion", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Reembolso reembolso;

    public enum EstadoDevolucion {
        solicitada, en_revision, aprobada, rechazada
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Devolucion)) return false;
        Devolucion that = (Devolucion) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
